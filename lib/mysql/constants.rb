class Mysql
  MAX_PACKET_LENGTH  = 256*256*256-1
  MAX_ALLOWED_PACKET = 1024*1024*1024

  MYSQL_UNIX_ADDR  = "/tmp/mysql.sock"
  MYSQL_PORT       = 3306
  PROTOCOL_VERSION = 10

  SCRAMBLE_LENGTH     = 20
  SCRAMBLE_LENGTH_323 = 8

  # Command
  COM_SLEEP          = 0
  COM_QUIT           = 1
  COM_INIT_DB        = 2
  COM_QUERY          = 3
  COM_FIELD_LIST     = 4
  COM_CREATE_DB      = 5
  COM_DROP_DB        = 6
  COM_REFRESH        = 7
  COM_SHUTDOWN       = 8
  COM_STATISTICS     = 9
  COM_PROCESS_INFO   = 10
  COM_CONNECT        = 11
  COM_PROCESS_KILL   = 12
  COM_DEBUG          = 13
  COM_PING           = 14
  COM_TIME           = 15
  COM_DELAYED_INSERT = 16
  COM_CHANGE_USER    = 17
  COM_BINLOG_DUMP    = 18
  COM_TABLE_DUMP     = 19
  COM_CONNECT_OUT    = 20
  COM_REGISTER_SLAVE = 21

  # Client flag
  CLIENT_LONG_PASSWORD     = 1
  CLIENT_FOUND_ROWS        = 1 << 1
  CLIENT_LONG_FLAG         = 1 << 2
  CLIENT_CONNECT_WITH_DB   = 1 << 3
  CLIENT_NO_SCHEMA         = 1 << 4
  CLIENT_COMPRESS          = 1 << 5
  CLIENT_ODBC              = 1 << 6
  CLIENT_LOCAL_FILES       = 1 << 7
  CLIENT_IGNORE_SPACE      = 1 << 8
  CLIENT_PROTOCOL_41       = 1 << 9
  CLIENT_INTERACTIVE       = 1 << 10
  CLIENT_SSL               = 1 << 11
  CLIENT_IGNORE_SIGPIPE    = 1 << 12
  CLIENT_TRANSACTIONS      = 1 << 13
  CLIENT_RESERVED          = 1 << 14
  CLIENT_SECURE_CONNECTION = 1 << 15
  CLIENT_CAPABILITIES      = CLIENT_LONG_PASSWORD|CLIENT_LONG_FLAG|CLIENT_TRANSACTIONS
  PROTO_AUTH41             = CLIENT_PROTOCOL_41 | CLIENT_SECURE_CONNECTION

  # Connection Option
  OPT_CONNECT_TIMEOUT = 0
  OPT_COMPRESS        = 1
  OPT_NAMED_PIPE      = 2
  INIT_COMMAND        = 3
  READ_DEFAULT_FILE   = 4
  READ_DEFAULT_GROUP  = 5
  SET_CHARSET_DIR     = 6
  SET_CHARSET_NAME    = 7
  OPT_LOCAL_INFILE    = 8

  # Server Status
  SERVER_STATUS_IN_TRANS   = 1
  SERVER_STATUS_AUTOCOMMIT = 2

  # Refresh parameter
  REFRESH_GRANT   = 1
  REFRESH_LOG     = 2
  REFRESH_TABLES  = 4
  REFRESH_HOSTS   = 8
  REFRESH_STATUS  = 16
  REFRESH_THREADS = 32
  REFRESH_SLAVE   = 64
  REFRESH_MASTER  = 128
end