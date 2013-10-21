module Spread2RDF
  module Schema
    class Worksheet < Sheet

      def init
        index_columns!
      end

      def index_columns!
        index = start_coord.column_as_number
        each_column do |column|
          index_letter = Roo::Base.number_to_letter(index)
          column.instance_variable_set :@coord, index_letter
          parent = column
          until parent.is_a? Worksheet
            parent = parent.parent
            column_index = parent.instance_variable_get :@column_index
            column_index[index_letter] = column
          end
          index += 1
        end
      end

    end
  end
end
