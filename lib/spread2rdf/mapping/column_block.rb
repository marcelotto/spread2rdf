module Spread2RDF
  module Mapping
    class ColumnBlock < Sheet
      include Statement

      def_delegators :parent, :subject, :row_range
      def_delegators :schema, :predicate

      def map
        super
        @resources.each do |resource|
          statements_to_object(resource.subject) unless resource.empty?
        end
        self
      end

      def objects
        @resources.map(&:subject)
      end

    end
  end
end
