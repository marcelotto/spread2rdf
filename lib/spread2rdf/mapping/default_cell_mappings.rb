module Spread2RDF
  module Mapping
    class Cell
      module Default
        def self.unit_mapping(value)
          @qudt ||= RDF::Graph.load File.join(ONTOLOGY_DIR, 'unit-v1.1.ttl')
          query = RDF::Query.new(
              unit: { RDF::URI.new('http://qudt.org/schema/qudt#symbol') =>
                        RDF::Literal.new(value, datatype: RDF::XSD.string) })
          solutions = query.execute(@qudt)
          raise "unit #{value} is not unique; possible candidates:
                    #{solutions.map(&:unit).ai}" if solutions.count > 1
          raise "couldn't find a QUDT unit for unit '#{value}''" if solutions.empty?
          solutions.first.unit
        end

        def self.uri_normalization(string)
          string
            .gsub(', ', '-')
            .gsub(' ', '-')
        end

      end
    end
  end
end
