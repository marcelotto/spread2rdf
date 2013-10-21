module Spread2RDF
  module Schema
    class ColumnBlock < Sheet
      include StatementMapping

      self.attributes = {
          predicate:  nil,
          statement:  nil
      }

      alias coord column_range

    end
  end
end