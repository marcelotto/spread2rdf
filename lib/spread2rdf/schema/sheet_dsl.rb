module Spread2RDF
  module Schema
    class Sheet
      class DSL
        def initialize(spreadsheet_dsl, worksheet, filename, &block)
          @spreadsheet_dsl = spreadsheet_dsl
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

        def column_block(name, options={}, &block)
          name = name.to_sym
          sub_sheet = @worksheet.column[name] ||= ColumnBlock.new(@worksheet)
          sub_sheet.update_attributes options.merge(name: name)
          DSL.new(@spreadsheet_dsl, sub_sheet, @filename, &block)
        end

        def cell(coord, options = {}, &block)
          content = ROO.cell(coord, @worksheet.source_name)
          content = block.call(content) if block_given?
          content
        end

        def include(template, *args)
          instance_exec(*args, &__template__(template))
        end

        def __template__(name)
          @spreadsheet_dsl.instance_variable_get(:@templates)[name]
        end
        private :__template__

        def method_missing(name, *args)
          __template__(name) or super
        end


      end
    end
  end
end
