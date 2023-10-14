# utility class to dry up answers
module HudApr::Generators::Shared::Fy2024
  class QuestionSheet
    attr_reader :report, :question
    def initialize(report:, question:)
      @report = report
      @question = question
    end

    def update_metadata(metadata)
      report.answer(question: question).update!(metadata: metadata)
    end

    def update_cell_value(cell:, value:)
      answer = report.answer(question: question, cell:  cell_code(cell))
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
