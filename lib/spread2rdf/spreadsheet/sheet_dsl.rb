module Spread2RDF
  class Spreadsheet
    class Sheet
      class DSL
        def initialize(sheet, &block)
          @sheet = sheet
          instance_exec(&block) if block_given?
        end

        def column(name, options={}, &block)
          name = name.to_sym
          column = @sheet.column[name] ||= Column.new(@sheet, &block)
          column.update_attributes options.merge(name: name)
          column # TODO: chaining logic ...?
        end

        def sub_sheet(name, options={}, &block)
          name = name.to_sym
          sub_sheet = @sheet.column[name] ||= SubSheet.new(@sheet)
          sub_sheet.update_attributes options.merge(name: name)
          Sheet::DSL.new(sub_sheet, &block)
        end
        alias column_block sub_sheet

        def cell(coord, options = {}, &block)
          content = @sheet.cell(coord)
          content = block.call(content) if block_given?
          content
        end

      end
    end
  end
end
