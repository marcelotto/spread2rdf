module Spread2RDF
  class Spreadsheet
    class Sheet
      class Column
        class MappingContext < Spreadsheet::MappingContext

          self.attributes = {
              subject:    nil,
              predicate:  nil,
              row:        nil
          }

          alias column element
          alias property predicate

          attr_reader :value

          def initialize(sheet, parent_context = nil, attr = {})
            super
            @value = cell_value(row: row, column: column.coord)
            return if @value.blank?
            statements_to_object
            worksheet.graph << self.graph
          end

          def cell_coord
            Coord[row: row, column: column.coord]
          end

          def subject
            @subject or parent_context.try(:subject)
          end

          def object
            @object ||= @value && map_to_object(value)
          end

          def value_of_column(name)
            other_column = sheet.column[name]
            raise "couldn't find column #{name} when mapping #{column}" if
                other_column.nil?
            cell_value(row: row, column: other_column.coord)
          end

          def object_of_column(name)
            other_column = sheet.column[name]
            raise "couldn't find column #{name} when mapping #{column}" if
                other_column.nil?
            cell(row: row, column: other_column.coord).object
          end

          ######################################################################
          # Value-to-object mapping

          private

          def map_to_object(value)
            case object_mapping_mode
              when :to_string
                value
              when :resource_ref
                resolve_resource_ref
              when :new_resource
                create_resource_object
              when :custom
                # TODO execute a mapping block in the context of Column::MappingContext
              else
                raise 'internal error: unknown column mapping type'
            end
          end


          def object_mapping_mode
            case
              when column.object.nil?         then :to_string
              when column.object.is_a?(Proc)  then :custom
              when !column.object[:uri].nil?  then :new_resource
              when !column.object[:from].nil? then :resource_ref
              else
                raise "mapping specification error: don't know how to map #{column}"
            end
          end

          def resolve_resource_ref
            source = column.object[:from]
            source = { worksheet: source } if source.is_a? Symbol
            raise ArgumentError, "expecting a Hash as source, but got #{source}" unless source.is_a? Hash
            source_worksheet = source[:worksheet]
            source_worksheet = spreadsheet.worksheet[source_worksheet]
            raise "#{column}: couldn't find source worksheet #{source[:worksheet]}" if source_worksheet.nil?
            source_predicate = source[:predicate] || RDF::RDFS.label
            result = source_worksheet.graph.query([nil, source_predicate, value])
            raise "#{column}: couldn't find a resource for #{value} in #{source_worksheet}" if result.empty?
            raise "#{column}: found multiple resources for #{value} in #{source_worksheet}: #{result.map(&:subject)}" if result.count > 1
            result.first.subject
          end

          # TODO: Should we reuse/share mapping logic with Sheet::MappingContext (#subject etc.)?
          def create_resource_object
            case
              when (column.object.try(:fetch, :uri, nil) || object) == :bnode
                RDF::Node.new
              else
                raise NotImplementedError
            end
          end


          ######################################################################
          # Statement mapping

          def statement_mapping_mode
            case
              when column.statement == :none then :ignore
              when column.statement == :none then :ignore
              when column.predicate.nil?     then :ignore
              when restriction_mode          then :restriction
              else                                :default
            end
          end

          def restriction_mode
            restriction_mode = column.statement
            case restriction_mode
              when :restriction then RDF::OWL.hasValue
              when Hash         then restriction_mode[:restriction]
              else nil
            end
          end

          def statements_to_object
            case statement_mapping_mode
              when :default
                statement(subject, predicate, object)
              when :restriction
                restriction_class = RDF::Node.new
                statements(
                    [ subject, RDF::RDFS.subClassOf, restriction_class ],
                    [ restriction_class, RDF.type, RDF::OWL.Restriction ],
                    [ restriction_class, RDF::OWL.onProperty, predicate ],
                    [ restriction_class, restriction_mode, object ]
                )
            end
            exec(value, &column.block) if column.block
          end

          def exec(value, &block)
            #puts "executing block of #{@___column___} in row #{row}"
            self.instance_exec(value, &block)
          end

        end
      end
    end
  end
end
