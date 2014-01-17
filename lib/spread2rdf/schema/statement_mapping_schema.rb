module Spread2RDF
  module Schema
    module StatementMapping

      def statement_mapping_mode
        case
          when statement == :none then :ignore
          when predicate.nil?     then :ignore
          when restriction_mode   then :restriction
          else                         :default
        end
      end

      def restriction_mode
        case statement
          when :restriction then RDF::OWL.hasValue
          when Hash         then statement[:restriction]
          else false
        end
      end

      def inverse_mode
        statement == :inverse ||
            ( statement.is_a?(Hash) && statement.try(:fetch, :inverse, false) )
      end

    end
  end
end
