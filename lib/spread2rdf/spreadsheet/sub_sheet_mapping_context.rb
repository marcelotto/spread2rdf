module Spread2RDF
  class Spreadsheet
    class SubSheet
      class MappingContext < Sheet::MappingContext

        self.attributes = {
        }

        alias sub_sheet element
        alias column_block element

        private

        ##########################################################################
        # Statement mapping
        # TODO: Duplication Column::MappingContext ! Share it ?

        def statement_mapping_mode
          case
            when column_block.statement == :none then :ignore
            when column_block.statement == :none then :ignore
            when column_block.predicate.nil?     then :ignore
            when restriction_mode                then :restriction
            else                                      :default
          end
        end

        def restriction_mode
          restriction_mode = column_block.statement
          case restriction_mode
            when :restriction then RDF::OWL.hasValue
            when Hash         then restriction_mode[:restriction]
            else nil
          end
        end

        def statements_to_object
          case statement_mapping_mode
            when :default
              statement(parent_context.subject, column_block.predicate, subject)
            when :restriction
              restriction_class = RDF::Node.new
              statements(
                  [ parent_context.subject, RDF::RDFS.subClassOf, restriction_class ],
                  [ restriction_class, RDF.type, RDF::OWL.Restriction ],
                  [ restriction_class, RDF::OWL.onProperty, column_block.predicate ],
                  [ restriction_class, restriction_mode, subject ]
              )
          end
        end

      end
    end
  end
end
