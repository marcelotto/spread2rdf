module Spread2RDF
  module Mapping
    class Cell < Element

      attr_reader :row

      def_delegators :parent, :subject, :worksheet, :resource
      def_delegators :schema, :predicate

      def initialize(sheet, parent, row)
        super(sheet, parent)
        @row = row
        map
      end

      def map
        exec(&schema.block) unless empty?
      end

      def coord
        Coord[column: schema.coord, row: row]
      end

      def value
        @value ||= worksheet.cell_value(coord)
      end

      def object
        @object ||= value && map_to_object(value)
      end

      def empty?
        value.blank?
      end

      def map_to_object(value)
        case schema.object_mapping_mode
          when :to_string     then value
          when :resource_ref  then resolve_resource_ref
          when :new_resource  then create_resource_object
          when :custom        # TODO execute a mapping block in the context of Column::MappingContext
          else raise 'internal error: unknown column mapping type'
        end
      end
      private :map_to_object

      def resolve_resource_ref
        source = schema.object[:from]
        source = { worksheet: source } if source.is_a? Symbol
        raise ArgumentError, "expecting a Hash as source, but got #{source}" unless source.is_a? Hash
        source_worksheet = source[:worksheet]
        source_worksheet = spreadsheet.worksheet(source_worksheet)
        raise "#{self}: couldn't find source worksheet #{source[:worksheet]}" if source_worksheet.nil?
        source_predicate = source[:predicate] || RDF::RDFS.label
        result = source_worksheet.graph.query([nil, source_predicate, value])
        raise "#{self}: couldn't find a resource for #{value} in #{source_worksheet}" if result.empty?
        raise "#{self}: found multiple resources for #{value} in #{source_worksheet}: #{result.map(&:subject)}" if result.count > 1
        result.first.subject
      end
      private :resolve_resource_ref

      def create_resource_object
        case
          when (schema.object.try(:fetch, :uri, nil) || object) == :bnode
            RDF::Node.new
          else
            raise NotImplementedError
        end
      end
      private :create_resource_object

      ##########################################################################
      # for the DSL for column statement blocks

      def value_of_column(name)
        sheet_schema = parent.parent.schema
        other_column = sheet_schema.column(name)
        raise "couldn't find column #{name} when mapping #{self}" if
            other_column.nil?
        worksheet.cell_value(column: other_column.coord, row: row)
      end

      def object_of_column(name)
        other_column = resource.column!(name)
        raise "couldn't find column #{name} when mapping #{self}" if
            other_column.nil?
        other_column.cell!(row).object
      end

      def exec(&block)
        #puts "executing block of #{@___column___} in row #{row}"
        self.instance_exec(value, &block) if block_given?
      end
      private :exec

      ##########################################################################
      # Element#_children_

      def _children_
        nil
      end

    end
  end
end
