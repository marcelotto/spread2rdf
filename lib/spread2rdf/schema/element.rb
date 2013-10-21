require 'forwardable'

module Spread2RDF
  module Schema
    class Element
      include Attributes
      extend Forwardable

      self.attributes = {
          name:         nil,
          source_name:  nil
      }

      attr_reader :parent
      attr_reader :block

      def_delegators :parent, :spreadsheet

      def initialize(parent, attr = {}, &block)
        @parent   = parent
        @block    = block
        init_attributes(attr)
      end

      def name
        (@name or @source_name).try(:to_sym)
      end

      def source_name
        (@source_name or @name).try(:to_s)
      end

      def worksheet
        return self if self.is_a? Worksheet
        parent = self.parent
        parent = parent.parent until parent.is_a? Worksheet or parent.nil?
        parent
      end

      def to_s
        name = (self.name.to_s == self.source_name.to_s ?
            self.name : "#{self.name} (#{self.source_name})" )
        "#{self.class.name.split('::').last}-schema #{name}"
      end

    end
  end
end

