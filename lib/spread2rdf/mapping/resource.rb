module Spread2RDF
  module Mapping
    class Resource < Element

      attr_reader :row_range

      def_delegators :parent, :worksheet

      def initialize(sheet, parent, row_range)
        super(sheet, parent)
        @columns = {}
        @row_range = row_range
        map
      end

      def map
        #puts "processing #{self} in #{row_range}"
        object_columns = parent.schema.columns - [parent.schema.subject_column]
        object_columns.each { |column| column!(column) }
        subject_description unless empty?
        self
      end

      ##########################################################################
      # subject mapping

      include ResourceCreation

      def subject
        @subject ||= create_resource
      end

      def subject_value
        cells = row_range.map do |row|
          parent.cell_value(row: row, column: schema.subject_column.coord).presence
        end.compact
        raise "no subject found for Resource in #{row_range} of #{sheet}" if cells.empty?
        raise "multiple subjects found for Resource in #{row_range} of #{sheet}: #{cells.inspect}" if cells.count > 1
        cells.first
      end
      alias resource_creation_value subject_value
      private :subject_value

      def subject_description
        type = schema.subject_resource_type
        statement(subject, RDF.type, type) unless type.nil?
        if type == RDF::RDFS.Class &&
            super_class = schema.subject.try(:fetch, :sub_class_of, nil)
          statement(subject, RDF::RDFS.subClassOf, super_class)
        end
      end
      private :subject_description

      ##########################################################################
      # Mapping::Element structure

      def columns
        @columns.values
      end
      alias _children_ columns

      def column(name)
        @columns[column_schema(name).name]
      end

      def column!(name)
        column_schema = column_schema(name)
        @columns[column_schema.name] ||= case column_schema
          when Schema::Column      then Column.new(column_schema, self)
          when Schema::ColumnBlock then ColumnBlock.new(column_schema, self).map
        end
      end

      def column_schema(name)
        case name
          when Schema::Column, Schema::ColumnBlock then name
          when String, Symbol                      then schema.column(name)
          else raise ArgumentError
        end
      end

    end
  end
end
