class Mysql
  class Field
    # Field type
    TYPE_DECIMAL = 0
    TYPE_TINY = 1
    TYPE_SHORT = 2
    TYPE_LONG = 3
    TYPE_FLOAT = 4
    TYPE_DOUBLE = 5
    TYPE_NULL = 6
    TYPE_TIMESTAMP = 7
    TYPE_LONGLONG = 8
    TYPE_INT24 = 9
    TYPE_DATE = 10
    TYPE_TIME = 11
    TYPE_DATETIME = 12
    TYPE_YEAR = 13
    TYPE_NEWDATE = 14
    TYPE_ENUM = 247
    TYPE_SET = 248
    TYPE_TINY_BLOB = 249
    TYPE_MEDIUM_BLOB = 250
    TYPE_LONG_BLOB = 251
    TYPE_BLOB = 252
    TYPE_VAR_STRING = 253
    TYPE_STRING = 254
    TYPE_GEOMETRY = 255
    TYPE_CHAR = TYPE_TINY
    TYPE_INTERVAL = TYPE_ENUM

    # Flag
    NOT_NULL_FLAG = 1
    PRI_KEY_FLAG = 2
    UNIQUE_KEY_FLAG  = 4
    MULTIPLE_KEY_FLAG  = 8
    BLOB_FLAG = 16
    UNSIGNED_FLAG = 32
    ZEROFILL_FLAG = 64
    BINARY_FLAG = 128
    ENUM_FLAG = 256
    AUTO_INCREMENT_FLAG = 512
    TIMESTAMP_FLAG  = 1024
    SET_FLAG = 2048
    NUM_FLAG = 32768
    PART_KEY_FLAG = 16384
    GROUP_FLAG = 32768
    UNIQUE_FLAG = 65536

    def initialize(table, org_table, name, length, type, flags, decimals, def_value, max_length)
      @table = table
      @org_table = org_table
      @name = name
      @length = length
      @type = type
      @flags = flags
      @decimals = decimals
      @def = def_value
      @max_length = max_length
      if (type <= TYPE_INT24 and (type != TYPE_TIMESTAMP or length == 14 or length == 8)) or type == TYPE_YEAR then
        @flags |= NUM_FLAG
      end
    end
    attr_reader :table, :org_table, :name, :length, :type, :flags, :decimals, :def, :max_length

    def inspect()
      "#<#{self.class}:#{@name}>"
    end
  end
end
