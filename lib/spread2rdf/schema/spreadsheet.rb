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

      def sorted_worksheets
        unsorted_worksheets, sorted_worksheets = worksheets, []
        unsorted_worksheets.reject! do |worksheet|
          worksheet.columns.empty? and sorted_worksheets << worksheet
        end
        while not unsorted_worksheets.empty?
          independent = unsorted_worksheets.find_index { |worksheet|
            unsorted_worksheets.none? do |other_worksheet|
              worksheet.depends_on? other_worksheet
            end
          }
          raise "schema contains cyclic dependencies" if independent.nil?
          sorted_worksheets << unsorted_worksheets.delete_at(independent)
        end
        sorted_worksheets
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
