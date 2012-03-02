module Sapphire
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 1
    TINY  = 1

    ARRAY    = [MAJOR, MINOR, TINY].compact
    STRING   = ARRAY.join('.')

    def self.to_a; ARRAY  end
    def self.to_s; STRING end
  end
end