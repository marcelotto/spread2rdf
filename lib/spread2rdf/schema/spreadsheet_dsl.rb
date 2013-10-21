module Spread2RDF
  module Schema
    class Spreadsheet
      class DSL

        def initialize(schema, filename)
          @schema = schema
          @filename = filename
        end

        def namespaces(namespaces)
          namespaces.each { |name, namespace| Namespace[name] = namespace }
        end

        def worksheet(name, options={}, &block)
          source_name = options[:source_name] = name
          name = ( options.delete(:name) || source_name ).to_sym
          worksheet = @schema.worksheet[name] ||= Worksheet.new(@schema)
          worksheet.update_attributes options.merge(name: name, source_name: source_name)
          Sheet::DSL.new(worksheet, @filename, &block)
        end

      end
    end
  end
end