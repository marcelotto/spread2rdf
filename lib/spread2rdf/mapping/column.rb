module Spread2RDF
  module Mapping
    class Column < Element
      include Statement

      def_delegators :parent, :subject, :worksheet, :row_range
      def_delegators :schema, :predicate

      alias resource parent

      def initialize(sheet, parent)
        super
        @cells = {}
        map(row_range)
      end

      def map(range)
        #puts "mapping #{self} in #{range} ..."
        case range
          when Integer
            cell = cell!(range)
            statements_to_object(cell.object) unless cell.empty?
          when Range
            range.each { |row| self.map(row) }
          else raise ArgumentError
        end
      end

      def objects
        cells.map(&:object)
      end

      def cell_coord(row)
        case row
          when Integer then Coord[column: schema.coord, row: row]
          when Coord   then Coord
          when Hash    then Coord[row]
          else raise ArgumentError
        end
      end

      ##########################################################################
      # Mapping::Element structure

      def cells
        @cells.values
      end
      alias _children_ cells

      def cell(coord)
        coord = cell_coord(coord)
        @cells[coord.to_sym] # TODO: search @sub_sheet_mappings also
      end

      def cell!(coord)
        coord = cell_coord(coord)
        @cells[coord.to_sym] ||= Cell.new(schema, self, coord.row)
      end

    end
  end
end

