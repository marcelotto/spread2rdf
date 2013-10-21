module Spread2RDF
  module Schema
    class << self
      def definition(*args, &block)
        definitions << Spreadsheet.new(*args, &block)
      end

      def definitions
        @@definitions ||= []
      end
    end

  end
end
