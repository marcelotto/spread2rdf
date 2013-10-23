module Spread2RDF
  module Schema
    class << self
      def definition(*args, &block)
        definitions << Spreadsheet.new(*args, &block)
      end

      def definitions
        @@definitions ||= []
      end

      def execute(options = {})
        CLI.run options.merge(schema: definitions.first) unless CLI.running?
      end

    end

  end
end
