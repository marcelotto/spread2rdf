module Spread2RDF
  module Mapping
    class Sheet < Element

      def initialize(sheet, parent)
        super
        @resources = []
      end

      def map
        #puts "processing #{self} in #{row_range}"
        return [] if row_range.nil? or schema.columns.empty?
        rows_per_resource.each do |resource_range|
          @resources << Mapping::Resource.new(schema, self, resource_range)
        end
        self
      end

      def rows_per_resource
        return [] if row_range.nil?
        @rows_per_resource ||= begin
          rows = if fix_row_count = schema.fix_row_count_per_resource
                   row_range.find_all do |row|
                     (row - row_range.begin) % fix_row_count == 0
                   end
                 else
                   subject_column_coord = schema.subject_column.try(:coord)
                   raise "no subject column for #{self}" if subject_column_coord.blank?
                   row_range.find_all do |row|
                     not cell(row: row, column: subject_column_coord).blank?
                   end
                 end
          rows_per_resource = []
          rows.each_with_index do |first_row, i|
            last_row = (i+1 == rows.count ? row_range.end : rows[i+1]-1)
            rows_per_resource << Range.new(first_row, last_row)
          end
          rows_per_resource
        end
      end

      ##########################################################################
      # Mapping::Element structure

      def worksheet
        return self if self.is_a? Worksheet
        parent = self.parent
        parent = parent.parent until parent.is_a? Worksheet or parent.nil?
        parent
      end

      attr_reader :resources
      alias _children_ resources

      def resource_by_row(row)
        index = rows_per_resource.find_index { |range| range.include? row }
        resource_by_index(index)
      end

      def resource_by_index(index)
        @resources[index]
      end

      ##########################################################################
      # Roo helper

      def cell_value(coord)
        value = ROO.cell(coord, schema.worksheet.source_name)
        value = value.strip if value.is_a? String
        value
      end
      alias cell cell_value

      def roo(&block)
        ROO.roo(schema.worksheet.source_name, &block)
      end

    end
  end
end
