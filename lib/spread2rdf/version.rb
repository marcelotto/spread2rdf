module Spread2RDF
  module VERSION
    FILE = File.expand_path('../../../VERSION', __FILE__)
    MAJOR, MINOR, TINY, EXTRA = File.read(FILE).chomp.split('.')
    STRING = [MAJOR, MINOR, TINY, EXTRA].compact.join('.').freeze

    ##
    # @return [String]
    def self.to_s() STRING end

    ##
    # @return [String]
    def self.to_str() STRING end

    ##
    # @return [Array(Integer, Integer, Integer)]
    def self.to_a() [MAJOR, MINOR, TINY] end
  end
end
