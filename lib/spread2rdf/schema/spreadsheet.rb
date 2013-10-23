module Spread2RDF
  module Schema
    class Spreadsheet

      attr_reader :name
      attr_reader :worksheet

      def initialize(name, &block)
        @name = name
        @worksheet = {}
        @schema_spec = block
      end

      def spreadsheet
        self
      end

      def worksheets
        @worksheet.values
      end

      def map(input_file)
        mapping = Mapping::Spreadsheet.new(self, input_file)
        DSL.new(self, input_file).instance_exec(&@schema_spec)
        worksheets.each { |worksheet| worksheet.init }
        mapping.map
        mapping
      end

    end
  end
end
