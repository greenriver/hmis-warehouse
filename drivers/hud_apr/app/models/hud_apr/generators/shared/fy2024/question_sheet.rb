# utility class to dry up answers
module HudApr::Generators::Shared::Fy2024
  # internal class
  class QuestionSheetColumnBuilder
    attr_reader :cell_members, :cell_values
    def initialize
      @cell_members = {}
      @cell_values = {}
    end

    def add_members(row:, members:)
      check_col(row)
      cell_members[check_row(row)] = members
    end

    def add_values(row:, value:)
      cell_values[check_row(row)] = value
    end

    protected

    def check_row(row)
      raise unless row.to_s =~ /[0-9]+/
      raise if cell_members.key?(row) || cell_values.key?(row)

      row
    end
  end

  # internal class
  class QuestionSheetRowBuilder
    attr_reader :cell_members, :cell_values
    def initialize
      @cell_members = {}
      @cell_values = {}
    end

    def add_members(col: next_column, members:)
      check_col(col)
      cell_members[check_col(col)] = members
    end

    def add_values(col: next_column, value:)
      cell_values[check_col(col)] = value
    end

    protected

    def check_col(col)
      col = col.to_s
      raise unless col =~ /[A-Z]+/
      raise if cell_members.key?(col) || cell_values.key?(col)

      col
    end

    def next_column
      max = [cell_members.keys.max, cell_values.keys.max].compact.max
      # we start at B since A is the row-label column
      max ? Util.next_column_identifier(max) : 'B'
    end
  end

  # internal class
  class QuestionSheetBuilder
    attr_reader :rows, :headers

    def initialize
      @rows = {}
      @headers = { 'A' => '' }
    end

    def with_row(label:)
      row = QuestionSheetRowBuilder.new
      yield(row)
      rows[label] = row
    end

    # def with_column(label: )
    #  col = QuestionSheetColumnBuilder.new
    #  yield(col)
    #  columns[label] = col
    # end

    def add_header(col: next_column, label:)
      raise unless col =~ /[A-Z]+/

      headers[col] = label
    end

    protected

    def next_column
      max = @headers.keys.max
      max ? Util.next_column_identifier(max) : 'A'
    end
  end

  class Util
    def self.next_column_identifier(column)
      # Convert the column identifier to an integer
      n = 0
      column.each_char do |char|
        n = n * 26 + (char.ord - 65 + 1) # 65 is the ASCII code for 'A', add 1 for 1-based indexing
      end

      # Increment the integer and convert it back to a column identifier
      n += 1

      result = ''
      while n.positive?
        remainder = (n - 1) % 26 # Subtracting 1 to handle 1-based indexing
        result = (65 + remainder).chr + result # 65 is the ASCII code for 'A'
        n = (n - 1) / 26 # Subtracting 1 to handle 1-based indexing
      end

      result
    end
  end

  class QuestionSheet
    attr_reader :report, :question

    def initialize(report:, question:)
      @report = report
      @question = question
    end

    def builder
      QuestionSheetBuilder.new
    end

    def build(builder)
      header_row = builder.headers.to_a.sort_by(&:first).map(&:last)

      first_row = 2
      metadata = {
        header_row: header_row,
        row_labels: builder.rows.keys,
        first_column: 'B',
        last_column: builder.headers.keys.max,
        first_row: first_row,
        last_row: 1 + builder.rows.size,
      }
      # FIXME: could use bulk insert for perf
      update_metadata(metadata)
      builder.rows.values.each.with_index(first_row) do |row, row_idx|
        row.cell_members.each do |column_letter, members|
          update_cell_members(cell: [column_letter, row_idx], members: members)
        end
        row.cell_values.each do |column_letter, value|
          update_cell_value(cell: [column_letter, row_idx], values: value)
        end
      end
    end

    def update_metadata(metadata)
      report.answer(question: question).update!(metadata: metadata)
    end

    def update_cell_value(cell:, value:)
      answer = report.answer(question: question, cell: cell_code(cell))
      answer.update!(summary: value)
      answer
    end

    def update_cell_members(cell:, members:)
      answer = report.answer(question: question, cell: cell_code(cell))
      answer.add_members(members)
      answer.update!(summary: members.size)
      answer
    end

    def cell_value(cell)
      report.answer(question: question, cell: cell_code(cell))&.value
    end

    protected

    def cell_code(cell)
      case cell
      when Array
        cell.join
      when String
        cell
      end
    end
  end
end
