require 'forwardable'

module Spread2RDF
  module Mapping
    class Element
      extend Forwardable

      attr_reader :schema
      attr_reader :parent

      def_delegators :parent, :spreadsheet

      def initialize(schema, parent)
        @graph = RDF::Repository.new
        @schema = schema
        @parent = parent
      end

      def to_s
        "#{self.class.name.split('::').last}-mapping of #{schema}"
      end

      ##########################################################################
      # children

      def _children_
        raise NotImplementedError, 'subclasses must implement this method'
      end

      def empty?
        _children_.empty? or _children_.all?(&:empty?)
      end

      ##########################################################################
      # RDF graph

      def graph
        if _children_
          _children_.inject(@graph.clone) { |graph, child| graph << child.graph }
        else
          @graph
        end
      end
      alias to_rdf graph

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
