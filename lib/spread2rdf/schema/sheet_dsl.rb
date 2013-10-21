module Spread2RDF
  module Schema
    class Sheet
      class DSL
        def initialize(worksheet, filename, &block)
          @worksheet = worksheet
          @filename = filename
          instance_exec(&block) if block_given?
        end

        def column(name, options={}, &block)
          name = name.to_sym
          column = @worksheet.column[name] ||= Column.new(@worksheet, &block)
          column.update_attributes options.merge(name: name)
          column # TODO: chaining logic ...?
        end

        def sub_sheet(name, options={}, &block)
          name = name.to_sym
          sub_sheet = @worksheet.column[name] ||= ColumnBlock.new(@worksheet)
          sub_sheet.update_attributes options.merge(name: name)
          DSL.new(sub_sheet, @filename, &block)
        end
        alias column_block sub_sheet

        def cell(coord, options = {}, &block)
          content = ROO.cell(coord, @worksheet.source_name)
          content = block.call(content) if block_given?
          content
        end

      end
    end
  end
end
