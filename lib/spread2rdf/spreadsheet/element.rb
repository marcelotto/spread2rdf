module Spread2RDF
  class Spreadsheet
    class Element
      include Attributes

      self.attributes = {
          name:         nil,
          source_name:  nil
      }

      attr_reader :parent
      attr_reader :block


      def initialize(parent, attr={}, &block)
        @parent   = parent
        @block    = block
        init_attributes(attr)
      end

      def init

      end

      def name
        (@name or @source_name).try(:to_sym)
      end

      def source_name
        (@source_name or @name).try(:to_s)
      end

      def spreadsheet
        parent.spreadsheet
      end

      def to_s
        name = (self.name.to_s == self.source_name.to_s ?
            self.name : "#{self.name} (#{self.source_name})" )
        "#{self.class.name.split('::').last} #{name}"
      end

    private

      def create_context(parent_context, attr)
        context_class = self.class.const_get(:MappingContext)
        context_class.new(self, parent_context, attr)
      end

    end
  end
end

