module Spread2RDF
  class Spreadsheet
    class Sheet
      class Column < Element

        attr_reader :coord # this is set by Worksheet#index_columns!

        self.attributes = {
            predicate:  nil,
            object:     nil,
            statement:  nil
        }

        def initialize(sheet, options = {}, &block)
          super
        end

        alias sheet parent

        def worksheet
          parent = self.parent
          parent = parent.parent until parent.is_a? Worksheet or parent.nil?
          parent
        end

        def map(range, context)
          #puts "mapping #{self} in #{range} ..."
          case range
            when Integer
              coord = Coord[row: range, column: self.coord]
              worksheet.cell_mapping[coord.to_sym] ||= mapping =
                  create_context(context, row: range,
                                 subject: context.subject, predicate: predicate)
              mapping.object
            when Range
              range.map { |row| self.map(row, context) }
            else raise ArgumentError
          end
        end

        def to_s
          "#{super} of #{sheet}"
        end

      end
    end
  end
end
