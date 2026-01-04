###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/hud-report-framework.md
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
      prepare_for_run
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

    # Override in subclasses to clean up derived data associated with this question
    def self.reset_derived_data(_report_instance)
      # Default implementation is a no-op
    end

    private

    # Resets this question's cells if the generator supports idempotent retry.
    # Safe to call on fresh runs - reset_question is a no-op if no cells exist.
    def prepare_for_run
      return unless @generator.class.supports_idempotent_retry?

      self.class.reset_derived_data(@report)
      @report.reset_question(self.class.question_number)
    end

    def household_query_service
      @household_query_service ||= HudReports::HouseholdQueryService.new(@report, a_t)
    end

    # Returns the report universe joined with the pre-computed household context.
    #
    # The returned relation is decorated with semantic reporting scopes defined in
    # HudReports::HouseholdQueryService::Filters. These scopes (e.g., .chronically_homeless)
    # allow for clean, SQL-based population filtering without leaking table aliases.
    def members
      @members ||= household_query_service.with_household_context(raw_universe.members)
    end

    def raw_universe
      @report.universe(self.class.question_number)
    end

    def sub_populations
      @sub_populations ||= household_query_service.sub_populations
    end

    def hh_ctx
      household_query_service.hh_ctx
    end

    def hoh_clause
      household_query_service.hoh_clause
    end

    def hoh_or_spouse_clause
      household_query_service.hoh_or_spouse_clause
    end

    def adult_or_hoh_clause
      household_query_service.adult_or_hoh_clause
    end

    def strict_leavers_clause
      household_query_service.strict_leavers_clause(@report.end_date)
    end

    def chronic_household_clause
      household_query_service.chronic_household_clause
    end

    def parenting_youth_clause
      household_query_service.parenting_youth_clause
    end

    def youth_only_clause
      household_query_service.youth_only_clause
    end

    def between_ages_clause(range)
      household_query_service.between_ages_clause(range)
    end

    def hoh_exit_date(household_id)
      @hoh_exit_dates ||= household_query_service.hoh_exit_dates(members)
      @hoh_exit_dates[household_id]
    end
  end
end
