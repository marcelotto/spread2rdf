module Spread2RDF
  module Mapping
    class Spreadsheet < Element

      attr_reader :input_file

      def initialize(schema, filename)
        super(schema, nil)
        @worksheets = {}
        @input_file = filename
        ROO.load(filename)
      end

      def map
        schema.worksheets.each { |worksheet_schema| worksheet!(worksheet_schema) }
        self
      end

      def worksheet_schema(name)
        case name
          when Schema::Worksheet then name
          when String, Symbol    then schema.worksheet[name]
          else raise ArgumentError
        end
      end

      ##########################################################################
      # Mapping::Element structure

      def spreadsheet
        self
      end

      def worksheets
        @worksheets.values
      end
      alias _children_ worksheets

      def worksheet(name)
        @worksheets[worksheet_schema(name).name]
      end

      def worksheet!(name)
        worksheet_schema = worksheet_schema(name)
        @worksheets[worksheet_schema.name] || begin
          @worksheets[worksheet_schema.name] = mapping =
              Mapping::Worksheet.new(worksheet_schema, self)
          mapping.map
        end
      end

    end
  end
end
