module Spread2RDF
  class Spreadsheet
    class MappingContext
      include Attributes

      self.attributes = {
      }

      attr_reader :element
      attr_reader :parent_context

      attr_reader :graph

      def initialize(element, parent_context, attr = {})
        @element = element
        @parent_context = parent_context
        @graph = RDF::Repository.new
        init_attributes(attr)
      end

      def sheet
        @element.sheet
      end

      def worksheet
        @element.worksheet
      end

      def spreadsheet
        @element.spreadsheet
      end

      def cell_value(coord)
        worksheet.cell(coord)
      end

      def cell(coord)
        coord = Coord[coord] unless coord.is_a? Coord
        worksheet.cell_mapping[coord.to_sym]
      end

      def to_s
        "#{self.class.name.split('::')[-2..-1].join('::')} of #{element}"
      end

      ##########################################################################
      # statement generators

      private

      def add_statement(*args)
        args = args.first if args.count == 1 and args.first.is_a? Array
        #puts "adding statement: #{args.inspect}"
        raise "internal error: trying to add a bad triple with nil value: #{args}" if args.count != 3 or args.one? { |arg| arg.nil? }
        @graph << RDF::Statement.new(*args)
      end
      alias statement add_statement

      def add_statements(*args)
        args = args.first if args.count == 1 and args.first.is_a? Array
        args.each { |arg| statement(arg) }
      end
      alias statements add_statements

    end
  end
end
