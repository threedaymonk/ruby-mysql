class Mysql
  class Result
    def initialize(mysql, fields, field_count, data=nil)
      @handle = mysql
      @fields = fields
      @field_count = field_count
      @data = data
      @current_field = 0
      @current_row = 0
      @eof = false
      @row_count = 0
    end
    attr_accessor :eof

    def data_seek(n)
      @current_row = n
    end

    def fetch_field()
      return if @current_field >= @field_count
      f = @fields[@current_field]
      @current_field += 1
      f
    end

    def fetch_fields()
      @fields
    end

    def fetch_field_direct(n)
      @fields[n]
    end

    def fetch_lengths()
      @data ? @data[@current_row].map{|i| i ? i.length : 0} : @lengths
    end

    def fetch_row()
      if @data then
        if @current_row >= @data.length then
          @handle.status = :STATUS_READY
          return
        end
        ret = @data[@current_row]
        @current_row += 1
      else
        return if @eof
        ret = @handle.read_one_row @field_count
        if ret == nil then
          @eof = true
          return
        end
        @lengths = ret.map{|i| i ? i.length : 0}
        @row_count += 1
      end
      ret
    end

    def fetch_hash(with_table=nil)
      row = fetch_row
      return if row == nil
      hash = {}
      @fields.each_index do |i|
        f = with_table ? @fields[i].table+"."+@fields[i].name : @fields[i].name
        hash[f] = row[i]
      end
      hash
    end

    def field_seek(n)
      @current_field = n
    end

    def field_tell()
      @current_field
    end

    def free()
      @handle.skip_result
      @handle = @fields = @data = nil
    end

    def num_fields()
      @field_count
    end

    def num_rows()
      @data ? @data.length : @row_count
    end

    def row_seek(n)
      @current_row = n
    end

    def row_tell()
      @current_row
    end

    def each()
      while row = fetch_row do
        yield row
      end
    end

    def each_hash(with_table=nil)
      while hash = fetch_hash(with_table) do
        yield hash
      end
    end

    def inspect()
      "#<#{self.class}>"
    end
  end
end
