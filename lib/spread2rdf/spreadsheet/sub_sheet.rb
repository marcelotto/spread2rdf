module Spread2RDF
  class Spreadsheet
    class SubSheet < Sheet

      self.attributes = {
          predicate:  nil,
          statement:  nil
      }

      alias coord column_range

    end
  end
end