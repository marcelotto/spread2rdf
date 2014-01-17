module Spread2RDF
  module Schema
    class Sheet < Element
      include ResourceCreation

      self.attributes = {
          start:                  :A2,
          subject:                nil,
          row_count_per_resource: nil  # TODO: document this in the README
      }

      def initialize(parent, attr = {}, &block)
        super
        @column = {}
        @column_index = {}
      end

      def resource_creation_attributes
        subject
      end

      def start_coord
        Coord[start]
      end

      def column_by_coord(coord)
        coord = Roo::Base.number_to_letter(coord) if coord.is_a? Integer
        @column_index[coord]
      end

      def column_by_name(name = nil)
        return @column if name.nil?
        name = name.to_sym
        @column[name] or ( parent.is_a?(Sheet) and parent.column(name) ) or nil
      end
      alias column column_by_name

      def columns
        @column.values
      end

      def column_range
        first = columns.first.coord
        first = first.begin if first.is_a? Range
        last = columns.last.coord
        last = last.end if last.is_a? Range
        first .. last
      end

      def each_column(&block)
        columns.each do |column|
          if column.is_a? ColumnBlock
            column.each_column(&block)
          else
            yield column
          end
        end
      end

      def subject_column
        column_name =
            ((subject = self.subject) &&
                ( ( subject[:uri].is_a?(Hash) && subject[:uri][:column] ) ||
              subject[:column])) || :uri
        @column[column_name]
      end

      def fix_row_count_per_resource
        row_count_per_resource or ( !subject_column && 1 ) or nil
      end

      def subject_resource_type
        subject.try(:fetch, :type, nil) or
            (subject.try(:fetch, :sub_class_of, nil) && RDF::RDFS.Class) or
            nil
      end

    end
  end
end
