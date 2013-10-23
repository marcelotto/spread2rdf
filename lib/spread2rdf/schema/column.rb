module Spread2RDF
  module Schema
    class Column < Element
      include StatementMapping

      self.attributes = {
          predicate:  nil,
          object:     nil,
          statement:  nil
      }

      attr_reader :coord # this is set by Worksheet#index_columns!

      alias sheet parent

      def to_s
        "#{super} of #{sheet}"
      end

      def object_mapping_mode
        case
          when object.nil?         then :to_string
          when object.is_a?(Proc)  then :custom
          when !object[:uri].nil?  then :new_resource
          when !object[:from].nil? then :resource_ref
          else
            raise "mapping specification error: don't know how to map #{self}"
        end
      end

      def cell_mapping
        object if object.is_a?(Proc)
      end

    end
  end
end
