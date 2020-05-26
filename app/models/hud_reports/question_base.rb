###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class QuestionBase
    def self.last_run(generator, user)
      last_answer(generator, user)&.created_at
    end

    def self.status(generator, user)
      last_answer(generator, user)&.status
    end

    def self.completed_in(generator, user)
      last_answer(generator, user)&.completed_in
    end

    def self.last_answer(generator, user)
      reports(generator, user).last&.answer(question: question_number)
    end

    def self.reports(generator, user)
      HudReports::ReportInstance.where(
        report_name: generator.title,
        user_id: user.id,
      )
    end
  end
end