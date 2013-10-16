module Spread2RDF
  module Namespace
    class << self
      def [](name)
        name = name.to_sym
        self.namespace[name] ||
            ( RDF.const_defined?(name) && RDF.const_get(name)) ||
            nil
      end

      def []=(name, namespace)
        name = name.to_sym
        self.namespace[name] = case namespace
          when RDF::Vocabulary          then namespace
          when String, RDF::URI         then RDF::Vocabulary.new(namespace)
          else raise ArgumentError, "expecting a namespace but got #{namespace}:#{namespace.class}"
        end
      end

      def namespace
        @namespace ||= {}
      end

      def namespaces
        namespace.values
      end

      def resolve_to_namespace(namespace_descriptor)
        case namespace_descriptor
          when Symbol
            Namespace[namespace_descriptor]
          when RDF::Vocabulary, RDF::URI, String
            namespace_descriptor.to_s
          else
            raise "invalid namespace: #{namespace_descriptor.inspect}"
        end
      end

      def const_missing(name)
        self[name] or super
      end
    end
  end
  NS = Namespace

  def self.const_missing(name)
    Namespace[name] or super
  end

end
