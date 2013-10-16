module Spread2RDF
  class Spreadsheet
    class Coord < Struct.new(:column, :row)
      def initialize(*args)
        case args.length
          when 2 then super
          when 1
            case args = args.first
              when Hash
                super(args[:column], args[:row])
              when Symbol, String
                coord = args.to_s
                raise "Invalid cell coordinates #{coord}" unless coord =~ /(\w+)(\d+)/
                super(Regexp.last_match[1], Regexp.last_match[2].to_i)
              else raise ArgumentError, "can't handle argument #{args}"
            end
          else raise ArgumentError, "too many arguments: #{args}"
        end
      end

      def column_as_number
        Roo::Base.letter_to_number(column)
      end

      def column_as_index
        column_as_number - 1
      end

      def increment_column(count = 1)
        self.class.increment_column(self.column, count)
      end

      def to_s
        "#{column}#{row}"
      end

      def to_sym
        to_s.to_sym
      end

      class << self
        alias [] new

        def increment_column(column, count=1)
          Roo::Base.number_to_letter(Roo::Base.letter_to_number(column) + count)
        end
      end

    end
  end
end