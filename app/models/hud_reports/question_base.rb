###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class QuestionBase
    def initialize(generator, report)
      @generator = generator
      @report = report
    end
    
    def self.last_answer(generator, user)
      reports(generator, user).order(created_at: :desc).each do |report|
        answer = report.answer(question: question_number)
        return answer if answer.completed?
      end
      nil
    end

    def self.reports(generator, user)
      HudReports::ReportInstance.where(
        report_name: generator.title,
        user_id: user.id,
      )
    end

    def self.question_number
      self::QUESTION_NUMBER
    end
  end
end