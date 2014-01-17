module Spread2RDF
  module Mapping
    module ResourceCreation

      def create_resource
        case schema.resource_creation_mode
          when :bnode                   then RDF::Node.new
          when :from_column_with_suffix then resource_from_suffix
          when :from_column             then resource_from_full_uri
          else raise 'unknown resource creation mode'
        end
      end

      def resource_from_full_uri
        RDF::URI.new(resource_creation_value, validate: true)
      end
      private :resource_from_full_uri

      def resource_from_suffix
        namespace = schema.resource_creation_namespace
        suffix = Mapping::Cell::Default.uri_normalization(resource_creation_value)
        #puts "creating resource " + RDF::URI.new("#{namespace}#{suffix}" )
        RDF::URI.new("#{namespace}#{suffix}")
      end
      private :resource_from_suffix

    end
  end
end
