module Spread2RDF
  class Spreadsheet
    class Sheet
      class MappingContext < Spreadsheet::MappingContext

        self.attributes = {
            row_range:  nil
        }

        alias sheet element

        def initialize(sheet, parent_context = nil, attr = {})
          super
          @objects = ( sheet.columns - [ sheet.subject_column ] ).map do |column|
            column.map(row_range, self).compact.presence
          end.compact
          return if @objects.empty?
          subject_description
          statements_to_object
          worksheet.graph << self.graph
        end

        ########################################################################
        # subject mapping

        # TODO: every new context instance (for the same cell) returns a different bnode, it must be stored ...
        def subject
          @subject ||= case subject_mapping_mode
             when :bnode         then RDF::Node.new
             when :from_column   then subject_resource_from_column
             else raise 'unknown subject mapping type'
           end
        end
        alias subject_resource subject

        def subject_resource_type
          sheet.subject.try(:fetch, :type, nil) or
              (sheet.subject.try(:fetch, :sub_class_of, nil) && RDF::RDFS.Class) or
              nil
        end

        def subject_namespace
          subject_namespace_name =
              sheet.subject.try(:fetch, :uri, nil).try(:fetch, :namespace, nil)
          Namespace.resolve_to_namespace(subject_namespace_name)
        end

      private

        def subject_mapping_mode
          case
            when ( sheet.subject.try(:fetch, :uri, nil) || sheet.subject ) == :bnode
              :bnode
            else
              :from_column
          end
        end

        def subject_name_suffix
          cells = row_range.map do |row|
            cell_value(row: row, column: sheet.subject_column.coord).presence
          end.compact
          raise "no subject found for #{sheet} in #{row_range}" if cells.empty?
          raise "multiple subjects found for #{sheet} in #{row_range}: #{cells.inspect}" if cells.count > 1
          cells.first
        end

        def subject_resource_from_column
          namespace = subject_namespace
          subject_suffix = Helper.resource_name(subject_name_suffix)
          #puts "subject resource for #{sheet} in #{range}: " + RDF::URI.new("#{namespace}#{subject_suffix}" )
          RDF::URI.new("#{namespace}#{subject_suffix}")
        end

        def subject_description
          type = subject_resource_type
          statement(subject, RDF.type, type) unless type.nil?
          if type == RDF::RDFS.Class &&
              super_class = sheet.subject.try(:fetch, :sub_class_of, nil)
            statement(subject, RDF::RDFS.subClassOf, super_class)
          end
        end

        def statements_to_object
        end

      end
    end
  end
end
