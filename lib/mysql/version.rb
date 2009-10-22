class Mysql
  module Version #:nodoc:
    MAJOR = 0
    MINOR = 2
    TINY  = 7

    STRING = [MAJOR, MINOR, TINY].join('.')
  end

  VERSION = "4.0-ruby-#{Version::STRING}-plus-changes"
end
