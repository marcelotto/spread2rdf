module Spread2RDF
  class Spreadsheet
    class Worksheet < Sheet

      self.attributes = {
      }

      attr_reader :cell_mapping
      attr_reader :graph

      def initialize(parent, options={}, &block)
        super
        @cell_mapping = {}
        @graph = RDF::Repository.new
      end

      def init
        index_columns!
      end

=begin
      def cell_mapping_by_name(name)

      end

      def cell_mapping_by_coord(coord)

      end
=end

      def index_columns!
        column_index = start_coord.column_as_number
        each_column do |column|
          column.instance_variable_set :@coord,
                                       Roo::Base.number_to_letter(column_index)
          column_index += 1
        end
      end

      def row_range
        range = roo { (Coord[start].row .. spreadsheet.roo.last_row) }
        range.begin <= range.end ? range : nil
      end

    private

    end
  end
end
