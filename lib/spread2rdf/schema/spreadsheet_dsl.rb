module Spread2RDF
  module Schema
    class Spreadsheet
      class DSL

        def initialize(schema, filename)
          @schema = schema
          @filename = filename
          @templates = {}
        end

        def namespaces(namespaces)
          namespaces.each { |name, namespace| Namespace[name] = namespace }
        end

        def worksheet(name, options={}, &block)
          source_name = options[:source_name] = name
          name = ( options.delete(:name) || source_name ).to_sym
          worksheet = @schema.worksheet[name] ||= Worksheet.new(@schema)
          worksheet.update_attributes options.merge(name: name, source_name: source_name)
          Sheet::DSL.new(self, worksheet, @filename, &block)
        end

        def template(name, &block)
          raise "required block for template #{name} missing" unless block_given?
          @templates[name.to_sym] = block
        end

        def method_missing(name, *args)
          @templates[name] or super
        end

      end
    end
  end
end