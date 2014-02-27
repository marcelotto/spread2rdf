module Spread2RDF
  module Mapping
    class Cell < Element
      include ResourceCreation

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
      alias resource_creation_value value

      def object
        @object ||= value && map_to_object(value)
      end

      def empty?
        value.blank?
      end

    private

      def map_to_object(value)
        case schema.object_mapping_mode
          when :to_string     then map_to_literal(value)
          when :resource_ref  then resolve_resource_ref
          when :new_resource  then create_resource
          when :custom        then exec(&schema.cell_mapping)
          else raise 'internal error: unknown column mapping mode'
        end
      end

      def map_to_literal(value)
        if language = schema.try(:object).try(:fetch, :language, nil)
          RDF::Literal.new(value, language: language.to_sym)
        elsif datatype = schema.try(:object).try(:fetch, :datatype, nil)
          RDF::Literal.new(value, datatype: datatype)
        else
          value
        end
      end

      def resolve_resource_ref
        source = schema.object[:from]
        if source[:worksheet] && result = resolve_resource_ref_from_worksheet(source[:worksheet])
          return result
        elsif source[:data_source] && result = resolve_resource_ref_from_data_sources(source[:data_source])
          return result
        else
          raise "#{self}: couldn't find a resource for #{value} in any of the defined sources"
        end
      end

      def resolve_resource_ref_from_worksheet(worksheet_name)
        worksheet = spreadsheet.worksheet(worksheet_name)
        raise "#{self}: couldn't find source worksheet #{worksheet_name}" if worksheet.nil?
        source_predicate = RDF::RDFS.label # TODO: make this configurable via a attribute in the schema definition
        query_subject(worksheet.graph, source_predicate, value, worksheet)
      end

      def resolve_resource_ref_from_data_sources(data_sources)
        raise ArgumentError, "expecting an Array, but got #{data_sources}" unless data_sources.is_a? Array
        data_sources.each do |data_source|
          result = resolve_resource_ref_from_data_source(data_source)
          return result if result
        end
        nil
      end

      def resolve_resource_ref_from_data_source(data_source)
        source_predicate = RDF::RDFS.label # TODO: make this configurable via a attribute in the schema definition
        query_subject(data_source, source_predicate, value)
      end

      def query_subject(data_source, predicate, value, data_source_name = nil)
        data_source_name ||= "data source #{data_source}"
        result = data_source.query([nil, predicate, map_to_literal(value)])
        return nil if result.empty?
        raise "#{self}: found multiple resources for #{value} in #{data_source_name}: #{result.map(&:subject)}" if result.count > 1
        result.first.subject
      end

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

      ##########################################################################
      # Element#_children_

      public

      def _children_
        nil
      end

    end
  end
end
