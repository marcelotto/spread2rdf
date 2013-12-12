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

      def dependent_sheets
        references = []
        each_column do |column|
          if column.object_mapping_mode == :resource_ref
            references << spreadsheet.worksheet[
                column.object[:from].try(:fetch, :worksheet)]
          end
        end
        references
      end

      def depends_on?(worksheet)
        return false unless worksheet.is_a? Worksheet
        return false if worksheet == self
        dependent_sheets = self.dependent_sheets
        return false if dependent_sheets.empty?
        return true if dependent_sheets.include? worksheet
        dependent_sheets.any? do |dependent_sheet|
          dependent_sheet != self and dependent_sheet.depends_on? worksheet
        end
      end

    end
  end
end
