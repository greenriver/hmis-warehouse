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
      answer = report.answer(question: question, cell: cell)
      answer.update!(summary: value)
      answer
    end

    def update_cell_members(cell:, members:)
      answer = report.answer(question: question, cell: cell)
      answer.add_members(members)
      answer.update!(summary: members.size)
      answer
    end
  end
end
