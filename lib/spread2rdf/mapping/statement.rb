module Spread2RDF
  module Mapping
    module Statement

      def statements_to_object(object)
        case schema.statement_mapping_mode
          when :default
            statement(subject, predicate, object)
          when :restriction
            restriction_class = RDF::Node.new
            statements(
                [ subject, RDF::RDFS.subClassOf, restriction_class ],
                [ restriction_class, RDF.type, RDF::OWL.Restriction ],
                [ restriction_class, RDF::OWL.onProperty, predicate ],
                [ restriction_class, schema.restriction_mode, object ]
            )
        end
      end
      private :statements_to_object
    end
  end
end
