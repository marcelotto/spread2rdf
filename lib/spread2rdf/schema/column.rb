module Spread2RDF
  module Schema
    class Column < Element
      include StatementMapping

      self.attributes = {
          predicate:  nil,
          object:     nil,
          statement:  nil
      }

      def self.normalize_attributes(values)
        if object = values[:object]
          case
            when object.is_a?(Proc) then # nothing
            when !(from = object.delete(:from_worksheet) ||
                          object.delete(:from_sheet)).nil?
              object[:from] = { worksheet: from.to_sym }
            when !(from = object.delete(:from_data_source)).nil?
              object[:from] = { data_source: resolve_data_sources(from) }
            when !(from = object[:from]).nil?
              case from
                when Symbol then object[:from] = { worksheet: from }
                when String then object[:from] = { data_source: resolve_data_sources(from) }
                when Hash
                  from[:data_source] = resolve_data_sources(from[:data_source]) if from.include?(:data_source)
              end
          end
        end
        values
      end

      def self.resolve_data_sources(data_sources)
        return [data_sources] unless data_sources.is_a? Array
        data_sources.map do |data_source|
          case
            when (uri = data_source).is_a?(RDF::URI) || (uri = RDF::URI.new(data_source)).valid?
              raise NotImplementedError, "resolving of uris is not implemented yet"
            when data_source.is_a?(String) && !(file = File.in_path(data_source)).nil?
              RDF::Graph.load file
            else puts "WARNING: couldn't resolve data source #{data_source}"
          end
        end.compact
      end

      attr_reader :coord # this is set by Worksheet#index_columns!

      alias sheet parent

      def to_s
        "#{super} of #{sheet}"
      end

      def object_mapping_mode
        case
          when object.nil?              then :to_string
          when object.is_a?(Proc)       then :custom
          when !object[:uri].nil?       then :new_resource
          when !object[:from].nil?      then :resource_ref
          when !object[:language].nil?  then :to_string
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
