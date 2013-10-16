require 'spread2rdf/spreadsheet/coord'
require 'spread2rdf/spreadsheet/element'
require 'spread2rdf/spreadsheet/mapping_context'
require 'spread2rdf/spreadsheet/sheet'
require 'spread2rdf/spreadsheet/sub_sheet'
require 'spread2rdf/spreadsheet/worksheet'
require 'spread2rdf/spreadsheet/sheet_mapping_context'
require 'spread2rdf/spreadsheet/sub_sheet_mapping_context'
require 'spread2rdf/spreadsheet/column'
require 'spread2rdf/spreadsheet/column_mapping_context'

require 'spread2rdf/spreadsheet/sheet_dsl'
require 'spread2rdf/spreadsheet/mapping_dsl'

module Spread2RDF
  class Spreadsheet

    attr_reader :name
    attr_reader :worksheet
    attr_reader :worksheet_mapping
    attr_reader :input_file
    attr_reader :roo

    def initialize(name, &block)
      @name = name
      @worksheet = {}
      @worksheet_mapping = {}
      @schema_spec = block
    end

    def spreadsheet
      self
    end

    def worksheets
      @worksheet.values
    end

    def templates
      @template.values
    end

    def read(filename)
      @input_file = filename
      load_roo
      load_schema
      load_resources
      self
    end

    def graph
      graph = RDF::Repository.new
      worksheets.each { |worksheet| graph << worksheet.graph }
      graph
    end
    alias to_rdf graph

  private

    # TODO: make this work with other spreadsheets than Excel
    def load_roo
      options = {}
      options[:packed], options[:file_warning] = :zip, :ignore if
          File.extname(@input_file).downcase == '.xlsm'
      @roo = Roo::Excelx.new(@input_file, options)
    end

    def load_schema
      Spreadsheet::MappingDSL.new(self).instance_exec(&@schema_spec)
      worksheets.each { |worksheet| worksheet.init }
    end

    def load_resources
      worksheets.each do |worksheet|
        next if worksheet.column.empty?
        worksheet.map
      end
    end

    class << self
      def definition(*args, &block)
        definitions << new(*args, &block)
      end
      private :new

      def definitions
        @@definitions ||= []
      end
    end

  end
end
