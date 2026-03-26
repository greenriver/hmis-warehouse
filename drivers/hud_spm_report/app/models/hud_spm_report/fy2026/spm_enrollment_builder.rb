# frozen_string_literal: true

module HudSpmReport::Fy2026
  # Maps HouseholdContext + Enrollment -> SpmEnrollment attributes
  # Similar to AprClientBuilder pattern
  class SpmEnrollmentBuilder
    SPM_COC_FUNDER_CODES = HudHelper.util('2026').spm_coc_funders.map(&:to_s).to_set.freeze

    def initialize(report:, enrollment:, context:, filter:, current_income:, previous_income:)
      @report = report
      @enrollment = enrollment
      @context = context
      @filter = filter
      @current_income = current_income
      @previous_income = previous_income
    end

    def self.build(...)
      new(...).build_attributes
    end

    def build_attributes
      client = @enrollment.client
      return unless client

      {
        report_instance_id: @report.id,
        first_name: client.first_name,
        last_name: client.last_name,
        client_id: @enrollment.destination_client.id,
        enrollment_id: @enrollment.id,
        personal_id: client.personal_id,
        data_source_id: @enrollment.data_source_id,

        # Pre-computed from HouseholdContext
        age: @context.age,
        start_of_homelessness: @context.inherited_date_to_street,
        move_in_date: @context.inherited_move_in_date,

        # Enrollment-specific
        entry_date: @enrollment.entry_date,
        exit_date: @enrollment.exit&.exit_date,
        project_type: @enrollment.project.project_type,
        eligible_funding: eligible_funding?,
        destination: @enrollment.exit&.destination,
        prior_living_situation: @enrollment.living_situation,
        length_of_stay: @enrollment.length_of_stay,
        los_under_threshold: @enrollment.los_under_threshold == 1,
        previous_street_essh: @enrollment.previous_street_essh == 1,

        # Income (from IncomeBenefit records)
        current_income_benefits_id: @current_income&.id,
        current_earned_income: earned_income(@current_income),
        current_non_employment_income: non_employment_income(@current_income),
        current_total_income: total_income(@current_income),
        previous_income_benefits_id: @previous_income&.id,
        previous_earned_income: earned_income(@previous_income),
        previous_non_employment_income: non_employment_income(@previous_income),
        previous_total_income: total_income(@previous_income),

        days_enrolled: calculate_days_enrolled,
      }
    end

    private

    def eligible_funding?
      @enrollment.project.funders.any? do |funder|
        funder.funder.in?(SPM_COC_FUNDER_CODES) &&
          (funder.end_date.nil? || funder.end_date >= @filter.start) &&
          (funder.start_date.nil? || funder.start_date <= @filter.end)
      end
    end

    def calculate_days_enrolled
      exit_date = [@enrollment.exit&.exit_date, @filter.end].compact.min
      (exit_date - @enrollment.entry_date).to_i + 1
    end

    def total_income(income_benefit)
      (income_benefit&.hud_total_monthly_income || 0).clamp(0..)
    end

    def earned_income(income_benefit)
      (income_benefit&.earned_amount || 0).clamp(0..)
    end

    def non_employment_income(income_benefit)
      (total_income(income_benefit) - earned_income(income_benefit)).clamp(0..)
    end
  end
end
