module Spread2RDF
  class Spreadsheet
    class Sheet < Element

      self.attributes = {
          subject:          nil,
          start:            :A2,
          row_count_per_resource: nil
      }

      def initialize(parent, options={}, &block)
        super(parent, options, &block)
        @column = {}
      end

      def worksheet
        return self if self.is_a? Worksheet
        parent = self.parent
        parent = parent.parent until parent.is_a? Worksheet or parent.nil?
        parent
      end

      def column(name = nil)
        return @column if name.nil?
        name = name.to_sym
        @column[name] or ( parent.is_a?(Sheet) and parent.column(name) ) or nil
      end

      def columns
        @column.values
      end

      def cell(coord)
        coord = Coord[coord]
        spreadsheet.roo.cell(coord.column, coord.row, worksheet.source_name)
      end

      def start_coord
        Coord[start]
      end

      def row_range
        raise NotImplementedError, 'subclasses of Sheet must implement this method'
      end

      def column_range
        first = columns.first.coord
        first = first.begin if first.is_a? Range
        last = columns.last.coord
        last = last.end if last.is_a? Range
        first .. last
      end

      def each_column(&block)
        columns.each do |column|
          if column.is_a? SubSheet
            column.each_column(&block)
          else
            yield column
          end
        end
      end

      def subject_column
        #return nil unless subject_mapping_type == :from_column
        column_name = self.subject.try(:fetch, :column, nil) || :uri
        @column[column_name]
      end

      def fix_row_count_per_resource
        row_count_per_resource or ( !subject_column && 1 ) or nil
      end

      def add_triple(*args)
        raise "internal error: trying to add a bad triple with nil value in #{self}: #{args}" if args.count != 3 or args.one? { |arg| arg.nil? }
        worksheet.graph << RDF::Statement.new(*args)
      end

      def map(row_range = self.row_range, context = nil)
        #puts "processing #{self} ..."
        return [] if row_range.nil?
        subjects = rows_per_resource(row_range).map do |resource_range|
          mapping = create_context(context, row_range: resource_range)
          spreadsheet.worksheet_mapping[worksheet.name] = mapping unless self.is_a? SubSheet
          mapping.subject
        end
        subjects
      end

    private

      def rows_per_resource(row_range)
        return [] if row_range.nil?
        rows = if fix_row_count = fix_row_count_per_resource
            row_range.find_all do |row|
              (row - row_range.begin) % fix_row_count == 0
            end
          else
            subject_column_coord = self.subject_column.try(:coord)
            raise "no subject column for #{self}" if subject_column_coord.blank?
            row_range.find_all do |row|
              not cell(row: row, column: subject_column_coord).blank?
            end
          end
        rows_per_resource = []
        rows.each_with_index do |first_row, i|
          last_row = (i+1 == rows.count ? row_range.end : rows[i+1]-1)
          rows_per_resource << Range.new(first_row, last_row)
        end
        rows_per_resource
      end

      def roo_select
        spreadsheet.roo.default_sheet = worksheet.source_name
      end

      def roo
        last_default_sheet = spreadsheet.roo.default_sheet
        roo_select
        return nil unless block_given?
        result = yield
        spreadsheet.roo.default_sheet = last_default_sheet
        result
      end

    end
  end
end
