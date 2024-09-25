###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class QuestionBase
    include NotifierConfig
    include ElapsedTimeHelper

    delegate :report_scope_source, to: :@generator

    def initialize(generator = nil, report = nil, options: {})
      setup_notifier('HudReports')
      options = options.with_indifferent_access
      if generator && report
        @generator = generator
        @report = report
      elsif options[:generator_class]
        raise 'Unknown HUD Report class' unless Rails.application.config.hud_reports[options[:generator_class]].present?

        @generator = options[:generator_class].constantize.new(options)
        @report = HudReports::ReportInstance.create(
          user_id: options['user_id'],
          coc_codes: options['coc_codes'],
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

    def run!
      run_question!
      remaining_questions = @report.remaining_questions - [self.class.question_number]
      @report.update(remaining_questions: remaining_questions)
    rescue StandardError => e
      # for debugging sql issues in tests, raise immediately since attempting further updates will crash in failed tx
      # and we'd like to get the backtrace from the original exception
      raise if Rails.env.test? && e.is_a?(ActiveRecord::StatementInvalid)

      sanitized_message = "#{e.message} at #{Rails.backtrace_cleaner.clean(e.backtrace, :all).join('; ')}}"
      @report.answer(question: self.class.question_number).update!(error_messages: sanitized_message, status: 'Failed')
      raise
    end

    def self.most_recent_answer(user:, report_name:)
      answer = ::HudReports::ReportCell.universe.where(question: question_number).
        joins(:report_instance).
        merge(::HudReports::ReportInstance.manual.where(report_name: report_name))
      answer = answer.merge(::HudReports::ReportInstance.where(user_id: user.id)) unless user.can_view_all_hud_reports?
      answer.order(created_at: :desc).first
    end

    def self.question_number
      self::QUESTION_NUMBER
    end

    def self.table_descriptions
      {}
    end
  end
end
