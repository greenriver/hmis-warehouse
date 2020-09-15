###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class QuestionBase
    def initialize(generator = nil, report = nil, options: {})
      options = options.with_indifferent_access
      if generator && report
        @generator = generator
        @report = report
      elsif options[:generator_class]
        raise 'Unknown HUD Report class' unless Rails.application.config.hud_reports[options[:generator_class]].present?

        @generator = options[:generator_class].constantize.new(options)
        @report = HudReports::ReportInstance.create(
          user_id: options['user_id'],
          coc_code: options['coc_code'],
          start_date: options['start_date'].to_date,
          end_date: options['end_date'].to_date,
          project_ids: options['project_ids'],
          state: 'Waiting',
          options: options,
          report_name: @generator.class.title,
          question_names: @generator.class.questions.keys,
        )
      else
        raise 'Unable to initialize Question'
      end
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
