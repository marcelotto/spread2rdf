require 'singleton'
module Spread2RDF
  class RooAdapter
    include Singleton

    def initialize

    end

    # TODO: make this work with other spreadsheets than Excel
    def load(file)
      options = {}
      options[:packed], options[:file_warning] = :zip, :ignore if
          File.extname(file).downcase == '.xlsm'
      @roo = Roo::Excelx.new(file, options)
    end

    def select_worksheet(worksheet)
      @roo.default_sheet = worksheet
    end

    def roo(worksheet = nil)
      return @roo if worksheet.nil?
      last_default_sheet = @roo.default_sheet
      select_worksheet(worksheet)
      return @roo unless block_given?
      result = yield @roo
      @roo.default_sheet = last_default_sheet
      result
    end

    def cell(coord, worksheet = nil)
      coord = Coord[coord] unless coord.is_a? Coord
      #if worksheet
        @roo.cell(coord.column, coord.row, worksheet)
      #else
      #  @roo.cell(coord.column, coord.row)
      #end
    end

  end

  ROO = RooAdapter.instance

end