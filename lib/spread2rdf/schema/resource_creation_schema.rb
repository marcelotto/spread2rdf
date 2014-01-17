module Spread2RDF
  module Schema
    module ResourceCreation

      def resource_creation_mode
        attr = self.resource_creation_attributes
        case
          when ( attr.try(:fetch, :uri, nil) || attr ) == :bnode
            :bnode
          when !( attr.try(:fetch, :uri, nil).try(:fetch, :namespace, nil) ).nil?
            :from_column_with_suffix
          else
            :from_column
        end
      end

      def resource_creation_namespace
        namespace_name =
            self.resource_creation_attributes.try(:fetch, :uri, nil).try(:fetch, :namespace, nil)
        return warn("No namespace for resource creation found") if namespace_name.nil?
        Namespace.resolve_to_namespace(namespace_name)
      end

    end
  end
end

