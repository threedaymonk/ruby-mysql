# Copyright (C) 2003-2005 TOMITA Masahiro
# tommy@tmtm.org
#

require "socket"
require "digest/sha1"

require "mysql/constants"
require "mysql/error"
require "mysql/field"
require "mysql/net"
require "mysql/result"
require "mysql/version"

class Mysql
  def initialize(*args)
    @client_flag = 0
    @max_allowed_packet = MAX_ALLOWED_PACKET
    @query_with_result = true
    @status = :STATUS_READY
    if args[0] != :INIT then
      real_connect(*args)
    end
  end

  def real_connect(host=nil, user=nil, passwd=nil, db=nil, port=nil, socket=nil, flag=nil)
    @server_status = SERVER_STATUS_AUTOCOMMIT
    if (host == nil or host == "localhost") and defined? UNIXSocket then
      unix_socket = socket || ENV["MYSQL_UNIX_PORT"] || MYSQL_UNIX_ADDR
      sock = UNIXSocket::new(unix_socket)
      @host_info = Error::err(Error::CR_LOCALHOST_CONNECTION)
      @unix_socket = unix_socket
    else
      sock = TCPSocket::new(host, port||ENV["MYSQL_TCP_PORT"]||(Socket::getservbyname("mysql","tcp") rescue MYSQL_PORT))
      @host_info = sprintf Error::err(Error::CR_TCP_CONNECTION), host
    end
    @host = host ? host.dup : nil
    sock.setsockopt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true
    @net = Net::new sock

    a = read
    @protocol_version = a.slice!(0)
    @server_version, a = a.split(/\0/,2)
    @thread_id, @scramble_buff = a.slice!(0,13).unpack("La8")
    if a.size >= 2 then
      @server_capabilities, = a.slice!(0,2).unpack("v")
    end
    if a.size >= 16 then
      @server_language, @server_status = a.slice!(0,3).unpack("cv")
    end

    flag = 0 if flag == nil
    flag |= @client_flag | CLIENT_CAPABILITIES
    flag |= CLIENT_CONNECT_WITH_DB if db

    @pre_411 = (0 == @server_capabilities & PROTO_AUTH41)
    if @pre_411
      data = Net::int2str(flag)+Net::int3str(@max_allowed_packet)+
             (user||"")+"\0"+
                   scramble(passwd, @scramble_buff, @protocol_version==9)
    else
      dummy, @salt2 = a.unpack("a13a12")
      @scramble_buff += @salt2
      flag |= PROTO_AUTH41
      data = Net::int4str(flag) + Net::int4str(@max_allowed_packet) +
             ([8] + Array.new(23, 0)).pack("c24") + (user||"")+"\0"+
             scramble41(passwd, @scramble_buff)
    end

    if db and @server_capabilities & CLIENT_CONNECT_WITH_DB != 0
      data << "\0" if @pre_411
      data << db
      @db = db.dup
    end
    write data
    pkt = read
    handle_auth_fallback(pkt, passwd)
    ObjectSpace.define_finalizer(self, Mysql.finalizer(@net))
    self
  end
  alias :connect :real_connect

  def handle_auth_fallback(pkt, passwd)
    # A packet like this means that we need to send an old-format password
    if pkt.size == 1 and pkt[0] == 254 and
       @server_capabilities & CLIENT_SECURE_CONNECTION != 0 then
      data = scramble(passwd, @scramble_buff, @protocol_version == 9)
      write data + "\0"
      read
    end
  end

  def escape_string(str)
    Mysql::escape_string str
  end
  alias :quote :escape_string

  def get_client_info()
    VERSION
  end
  alias :client_info :get_client_info

  def options(option, arg=nil)
    if option == OPT_LOCAL_INFILE then
      if arg == false or arg == 0 then
        @client_flag &= ~CLIENT_LOCAL_FILES
      else
        @client_flag |= CLIENT_LOCAL_FILES
      end
    else
      raise "not implemented"
    end
  end

  def real_query(query)
    command COM_QUERY, query, true
    read_query_result
    self
  end

  def use_result()
    if @status != :STATUS_GET_RESULT then
      error Error::CR_COMMANDS_OUT_OF_SYNC
    end
    res = Result::new self, @fields, @field_count
    @status = :STATUS_USE_RESULT
    res
  end

  def store_result()
    if @status != :STATUS_GET_RESULT then
      error Error::CR_COMMANDS_OUT_OF_SYNC
    end
    @status = :STATUS_READY
    data = read_rows @field_count
    res = Result::new self, @fields, @field_count, data
    @fields = nil
    @affected_rows = data.length
    res
  end

  def change_user(user="", passwd="", db="")
    if @pre_411
      data = user+"\0"+scramble(passwd, @scramble_buff, @protocol_version==9)+"\0"+db
    else
      data = user+"\0"+scramble41(passwd, @scramble_buff)+db
    end
    pkt = command COM_CHANGE_USER, data
    handle_auth_fallback(pkt, passwd)
    @user = user
    @passwd = passwd
    @db = db
  end

  def character_set_name()
    raise "not implemented"
  end

  def close()
    @status = :STATUS_READY
    command COM_QUIT, nil, true
    @net.close
    self
  end

  def create_db(db)
    command COM_CREATE_DB, db
    self
  end

  def drop_db(db)
    command COM_DROP_DB, db
    self
  end

  def dump_debug_info()
    command COM_DEBUG
    self
  end

  def get_host_info()
    @host_info
  end
  alias :host_info :get_host_info

  def get_proto_info()
    @protocol_version
  end
  alias :proto_info :get_proto_info

  def get_server_info()
    @server_version
  end
  alias :server_info :get_server_info

  def kill(id)
    command COM_PROCESS_KILL, Net::int4str(id)
    self
  end

  def list_dbs(db=nil)
    real_query "show databases #{db}"
    @status = :STATUS_READY
    read_rows(1).flatten
  end

  def list_fields(table, field=nil)
    command COM_FIELD_LIST, "#{table}\0#{field}", true
    if @pre_411
      f = read_rows 6
    else
      f = read_rows 7
    end
    fields = unpack_fields(f, @server_capabilities & CLIENT_LONG_FLAG != 0)
    res = Result::new self, fields, f.length
    res.eof = true
    res
  end

  def list_processes()
    data = command COM_PROCESS_INFO
    @field_count = get_length data
    if @pre_411
      fields = read_rows 5
    else
      fields = read_rows 7
    end
    @fields = unpack_fields(fields, @server_capabilities & CLIENT_LONG_FLAG != 0)
    @status = :STATUS_GET_RESULT
    store_result
  end

  def list_tables(table=nil)
    real_query "show tables #{table}"
    @status = :STATUS_READY
    read_rows(1).flatten
  end

  def ping()
    command COM_PING
    self
  end

  def query(query)
    real_query query
    if not @query_with_result then
      return self
    end
    if @field_count == 0 then
      return nil
    end
    store_result
  end

  def refresh(r)
    command COM_REFRESH, r.chr
    self
  end

  def reload()
    refresh REFRESH_GRANT
    self
  end

  def select_db(db)
    command COM_INIT_DB, db
    @db = db
    self
  end

  def shutdown()
    command COM_SHUTDOWN
    self
  end

  def stat()
    command COM_STATISTICS
  end

  attr_reader :info, :insert_id, :affected_rows, :field_count, :thread_id
  attr_accessor :query_with_result, :status

  def read_one_row(field_count)
    data = read
    if data[0] == 254 and data.length == 1 ## EOF
      return
    elsif data[0] == 254 and data.length == 5
      return
    end
    rec = []
    field_count.times do
      len = get_length data
      if len == nil then
        rec << len
      else
        rec << data.slice!(0,len)
      end
    end
    rec
  end

  def skip_result()
    if @status == :STATUS_USE_RESULT then
      loop do
        data = read
        break if data[0] == 254 and data.length == 1
      end
      @status = :STATUS_READY
    end
  end

  def inspect()
    "#<#{self.class}>"
  end

  private

  def read_query_result()
    data = read
    @field_count = get_length(data)
    if @field_count == nil then                # LOAD DATA LOCAL INFILE
      File::open(data) do |f|
        write f.read
      end
      write ""                # mark EOF
      data = read
      @field_count = get_length(data)
    end
    if @field_count == 0 then
      @affected_rows = get_length(data, true)
      @insert_id = get_length(data, true)
      if @server_capabilities & CLIENT_TRANSACTIONS != 0 then
        a = data.slice!(0,2)
        @server_status = a[0]+a[1]*256
      end
      if data.size > 0 and get_length(data) then
        @info = data
      end
    else
      @extra_info = get_length(data, true)
      if @pre_411
        fields = read_rows(5)
      else
        fields = read_rows(7)
      end
      @fields = unpack_fields(fields, @server_capabilities & CLIENT_LONG_FLAG != 0)
      @status = :STATUS_GET_RESULT
    end
    self
  end

  def unpack_fields(data, long_flag_protocol)
    ret = []
    data.each do |f|
      if @pre_411
        table = org_table = f[0]
        name = f[1]
        length = f[2][0]+f[2][1]*256+f[2][2]*256*256
        type = f[3][0]
        if long_flag_protocol then
          flags = f[4][0]+f[4][1]*256
          decimals = f[4][2]
        else
          flags = f[4][0]
          decimals = f[4][1]
        end
        def_value = f[5]
        max_length = 0
      else
        catalog = f[0]
        db = f[1]
        table = f[2]
        org_table = f[3]
        name = f[4]
        org_name = f[5]
        length = f[6][2]+f[6][3]*256+f[6][4]*256*256
        type = f[6][6]
        flags = f[6][7]+f[6][8]*256
        decimals = f[6][9]
        def_value = ""
        max_length = 0
      end
      ret << Field::new(table, org_table, name, length, type, flags, decimals, def_value, max_length)
    end
    ret
  end

  def read_rows(field_count)
    ret = []
    while rec = read_one_row(field_count) do
      ret << rec
    end
    ret
  end

  def get_length(data, longlong=nil)
    return if data.length == 0
    c = data.slice!(0)

    return c if c < 251

    case c
    when 251
      return nil
    when 252
      a = data.slice!(0,2)
      return a[0]+(a[1]<<8)
    when 253
      a = data.slice!(0,3)
      return a[0]+(a[1]<<8)+(a[2]<<16)
    when 254
      a = data.slice!(0,8)
      if longlong then
        return a[0]+(a[1]<<8)+(a[2]<<16) +(a[3]<<24)+(a[4]<<32)+(a[5]<<40)+(a[6]<<48)+(a[7]<<56)
      else
        return a[0]+(a[1]<<8)+(a[2]<<16)+(a[3]<<24)
      end
    else
      c
    end
  end

  def command(cmd, arg=nil, skip_check=nil)
    unless @net then
      error Error::CR_SERVER_GONE_ERROR
    end
    if @status != :STATUS_READY then
      error Error::CR_COMMANDS_OUT_OF_SYNC
    end
    @net.clear
    write cmd.chr+(arg||"")
    read unless skip_check
  end

  def read()
    unless @net then
      error Error::CR_SERVER_GONE_ERROR
    end
    a = @net.read
    if a[0] == 255 then
      if a.length > 3 then
        @errno = a[1]+a[2]*256
        @error = a[3 .. -1]
      else
        @errno = Error::CR_UNKNOWN_ERROR
        @error = Error::err @errno
      end
      raise Error::new(@errno, @error)
    end
    a
  end

  def write(arg)
    unless @net then
      error Error::CR_SERVER_GONE_ERROR
    end
    @net.write arg
  end

  def hash_password(password)
    nr = 1345345333
    add = 7
    nr2 = 0x12345671
    password.each_byte do |i|
      next if i == 0x20 or i == 9
      nr ^= (((nr & 63) + add) * i) + (nr << 8)
      nr2 += (nr2 << 8) ^ nr
      add += i
    end
    [nr & ((1 << 31) - 1), nr2 & ((1 << 31) - 1)]
  end

  def scramble(password, message, old_ver)
    return "" if password == nil or password == ""
    raise "old version password is not implemented" if old_ver
    hash_pass = hash_password password
    hash_message = hash_password message.slice(0,SCRAMBLE_LENGTH_323)
    rnd = Random::new hash_pass[0] ^ hash_message[0], hash_pass[1] ^ hash_message[1]
    to = []
    1.upto(SCRAMBLE_LENGTH_323) do
      to << ((rnd.rnd*31)+64).floor
    end
    extra = (rnd.rnd*31).floor
    to.map! do |t| (t ^ extra).chr end
    to.join
  end

  def scramble41(password, message)
    return 0x00.chr if password.nil? or password.empty?
    buf = [0x14]
    s1 = Digest::SHA1.digest(password)
    s2 = Digest::SHA1.digest(s1)
    x = Digest::SHA1.digest(message + s2)
    (0..s1.length - 1).each {|i| buf.push(s1[i] ^ x[i])}
    buf.pack("C*")
  end

  def error(errno)
    @errno = errno
    @error = Error::err errno
    raise Error::new(@errno, @error)
  end

  class Random
    def initialize(seed1, seed2)
      @max_value = 0x3FFFFFFF
      @seed1 = seed1 % @max_value
      @seed2 = seed2 % @max_value
    end

    def rnd()
      @seed1 = (@seed1*3+@seed2) % @max_value
      @seed2 = (@seed1+@seed2+33) % @max_value
      @seed1.to_f / @max_value
    end
  end

end

class << Mysql
  def init()
    Mysql::new :INIT
  end

  def real_connect(*args)
    Mysql::new(*args)
  end
  alias :connect :real_connect

  def finalizer(net)
    proc {
      net.clear
      begin
        net.write(Mysql::COM_QUIT.chr)
        net.close
      rescue  # Ignore IOError if socket is already closed.
      end
    }
  end

  def escape_string(str)
    str.gsub(/([\0\n\r\032\'\"\\])/) do
      case $1
      when "\0" then "\\0"
      when "\n" then "\\n"
      when "\r" then "\\r"
      when "\032" then "\\Z"
      else "\\"+$1
      end
    end
  end
  alias :quote :escape_string

  def get_client_info()
    Mysql::VERSION
  end
  alias :client_info :get_client_info

  def debug(str)
    raise "not implemented"
  end
end

#
# for compatibility
#

MysqlRes   = Mysql::Result
MysqlField = Mysql::Field
MysqlError = Mysql::Error
