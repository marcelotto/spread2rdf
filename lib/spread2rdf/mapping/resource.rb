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

      def subject
        @subject ||=
            case schema.subject_mapping_mode
              when :bnode                   then RDF::Node.new
              when :from_column_with_suffix then subject_resource_from_column_with_suffix
              when :from_column             then subject_resource_from_column
              else raise 'unknown subject mapping type'
            end
      end
      alias subject_resource subject

      def subject_resource_from_column
        RDF::URI.new(subject_value, validate: true)
      end
      private :subject_resource_from_column

      def subject_resource_from_column_with_suffix
        namespace = schema.subject_namespace
        subject_suffix = Mapping::Cell::Default.uri_normalization(subject_value)
        #puts "subject resource for #{sheet} in #{range}: " + RDF::URI.new("#{namespace}#{subject_suffix}" )
        RDF::URI.new("#{namespace}#{subject_suffix}")
      end
      private :subject_resource_from_column_with_suffix

      def subject_value
        cells = row_range.map do |row|
          parent.cell_value(row: row, column: schema.subject_column.coord).presence
        end.compact
        raise "no subject found for Resource in #{row_range} of #{sheet}" if cells.empty?
        raise "multiple subjects found for Resource in #{row_range} of #{sheet}: #{cells.inspect}" if cells.count > 1
        cells.first
      end
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
