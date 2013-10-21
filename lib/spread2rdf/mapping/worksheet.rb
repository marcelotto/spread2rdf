module Spread2RDF
  module Mapping
    class Worksheet < Sheet

      def row_range
        range = roo { |roo| (Coord[schema.start].row .. roo.last_row) }
        range.begin <= range.end ? range : nil
      end

    end
  end
end
