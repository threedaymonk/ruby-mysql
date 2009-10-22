class Mysql
  class Net
    def initialize(sock)
      @sock = sock
      @pkt_nr = 0
    end

    def clear()
      @pkt_nr = 0
    end

    def read()
      buf = []
      len = nil
      @sock.sync = false
      while len == nil or len == MAX_PACKET_LENGTH do
        a = @sock.read(4)
        len = a[0]+a[1]*256+a[2]*256*256
        pkt_nr = a[3]
        if @pkt_nr != pkt_nr then
          raise "Packets out of order: #{@pkt_nr}<>#{pkt_nr}"
        end
        @pkt_nr = @pkt_nr + 1 & 0xff
        buf << @sock.read(len)
      end
      @sock.sync = true
      buf.join
    rescue
      errno = Error::CR_SERVER_LOST
      raise Error::new(errno, Error::err(errno))
    end

    def write(data)
      if data.is_a? Array then
        data = data.join
      end
      @sock.sync = false
      ptr = 0
      while data.length >= MAX_PACKET_LENGTH do
        @sock.write Net::int3str(MAX_PACKET_LENGTH)+@pkt_nr.chr+data[ptr, MAX_PACKET_LENGTH]
        @pkt_nr = @pkt_nr + 1 & 0xff
        ptr += MAX_PACKET_LENGTH
      end
      @sock.write Net::int3str(data.length-ptr)+@pkt_nr.chr+data[ptr .. -1]
      @pkt_nr = @pkt_nr + 1 & 0xff
      @sock.sync = true
      @sock.flush
    rescue
      errno = Error::CR_SERVER_LOST
      raise Error::new(errno, Error::err(errno))
    end

    def close()
      @sock.close
    end

    def Net::int2str(n)
      [n].pack("v")
    end

    def Net::int3str(n)
      [n%256, n>>8].pack("cv")
    end

    def Net::int4str(n)
      [n].pack("V")
    end

  end
end
