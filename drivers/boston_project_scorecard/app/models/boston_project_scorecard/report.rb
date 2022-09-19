###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    acts_as_paranoid
    has_paper_trail

    # Calculations for report sections
    include Header
    include TotalScore
    include ProjectPerformance
    include DataQuality
    include FinancialPerformance
    include PolicyAlignment
    include RacialEquity

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    belongs_to :project_group, class_name: 'GrdaWarehouse::ProjectGroup', optional: true
    belongs_to :user, class_name: 'User', optional: true
    belongs_to :secondary_reviewer, class_name: 'User', optional: true
    belongs_to :apr, class_name: 'HudReports::ReportInstance', optional: true

    scope :started_between, ->(start_date:, end_date:) do
      where(started_at: (start_date..end_date))
    end

    def completed?
      status == 'completed'
    end

    def pending?
      status == 'pending'
    end

    def authorized?(_user)
      # TODO: determine if the user is authorized to access the report
      true
    end

    def locked?(field, _user)
      # TODO: Implement field access rules for users
      case status
      when 'pending'
        case field
        when :period_start_date, :period_end_date, :project_type, :secondary_reviewer_id
          # Allow editing the header while being pre-filled
          false
        else
          true
        end

      when 'pre-filled'
        # Entire form is editable after pre-filling
        false

      when 'ready'
        case field
        when :period_start_date, :period_end_date, :project_type, :secondary_reviewer_id
          # Lock header when ready
          true
        else
          false
        end

      else
        true
      end
    end

    def admin?(user)
      # The user that created the report is the admin
      user_id == user.id
    end

    def field_input_options(field, user)
      if locked?(field, user)
        { readonly: true }
      else
        {}
      end
    end

    private def score(value, ten_range, five_range = nil)
      return nil if value.blank?

      if ten_range.include?(value)
        10
      elsif five_range.present? && five_range.include?(value)
        5
      else
        0
      end
    end

    private def percentage_string(value)
      v = value.to_f
      v = 0 if v.nan?
      v = 0 if v.infinite?

      "#{v.round(2)}%"
    end

    private def percentage(value)
      v = value.to_f
      return 0 if v.nan?
      return 0 if v.infinite?

      (v * 100).round(2)
    end

    def controlled_parameters
      @controlled_parameters ||= [
        :project_type,
        :period_start_date,
        :period_end_date,
        :secondary_reviewer_id,
        :initial_goals_pass,
        :initial_goals_notes,
        :timeliness_pass,
        :timeliness_notes,
        :independent_living_pass,
        :independent_living_notes,
        :management_oversight_pass,
        :management_oversight_notes,
        :prioritization_pass,
        :prioritization_notes,
        :invoicing,
        :actual_households_served,
        :amount_agency_spent,
        :contracted_budget,
        :returned_funds,
        :practices_housing_first,
        :barrier_id_process,
        :plan_to_address_barriers,
        :required_match_percent_met,
      ].freeze
    end

    def controlled_array_parameters
      [
        :subpopulations_served,
        :vulnerable_subpopulations_served,
      ]
    end

    def project_name
      # TODO: Do we need confidentialization logic here?
      return project.name if project.present?

      project_group.name
    end

    def title
      _('MA-500 Boston Continuum of Care FY2022 Renewal Project Scoring Tool')
    end

    def url
      boston_project_scorecard_warehouse_reports_scorecard_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def run_and_save!
      update(started_at: Time.current)

      # previous = if project_id.present?
      #   self.class.where(project_id: project_id).
      #     where.not(id: id).
      #     order(id: :desc).
      #     first
      # else
      #   self.class.where(project_group_id: project_group_id).
      #     where.not(id: id).
      #     order(id: :desc).
      #     first
      # end
      apr = apr_report if RailsDrivers.loaded.include?(:hud_apr)
      project_type = if project_id.present?
        project.computed_project_type
      else
        project_group.projects.first.computed_project_type
      end
      update(project_type: project_type)

      assessment_answers = {}

      if apr.present?
        # Project Performance
        one_a_value = percentage(answer(apr, 'Q23c', 'B46'))
        one_b_value = percentage((answer(apr, 'Q5a', 'B1') - answer(apr, 'Q23c', 'B43') + answer(apr, 'Q23c', 'B44')) /
          (answer(apr, 'Q5a', 'B1') - answer(apr, 'Q23c', 'B45')).to_f)

        assessment_answers.merge!(
          {
            apr_id: apr.id,
            rrh_exits_to_ph: one_a_value,
            psh_stayers_or_to_ph: one_b_value,
            increased_stayer_employment_income: percentage(answer(apr, 'Q19a1', 'J2')),
            increased_stayer_other_income: percentage(answer(apr, 'Q19a1', 'J4')),
            increased_leaver_employment_income: percentage(answer(apr, 'Q19a2', 'J2')),
            increased_leaver_other_income: percentage(answer(apr, 'Q19a2', 'J4')),
            days_to_lease_up: answer(apr, 'Q22c', 'B11').round,
          },
        )

        # Data Quality
        # need unique count of client_ids not, sum of counts since someone might appear more than once
        total_served = answer(apr, 'Q5a', 'B1')
        total_ude_errors = (2..6).map { |row| answer_client_ids(apr, 'Q6b', 'B' + row.to_s) }.flatten.uniq.count
        percent_ude_errors = percentage(total_ude_errors / total_served.to_f)

        # Include adults, leavers, and all HoHs in denominators
        denominator = [2, 5, 14, 15].map { |row| answer_client_ids(apr, 'Q5a', 'B' + row.to_s) }.flatten.uniq.count
        total_income_and_housing_errors = (2..5).map { |row| answer_client_ids(apr, 'Q6c', 'B' + row.to_s) }.flatten.uniq.count
        percent_income_and_housing_errors = percentage(total_income_and_housing_errors / denominator.to_f)
        assessment_answers.merge!(
          {
            pii_error_rate: percentage(answer(apr, 'Q6a', 'F8')),
            ude_error_rate: percent_ude_errors,
            income_and_housing_error_rate: percent_income_and_housing_errors,
          },
        )

        # Financial performance
        utilization_values = [
          answer(apr, 'Q8b', 'B2'),
          answer(apr, 'Q8b', 'B3'),
          answer(apr, 'Q8b', 'B4'),
          answer(apr, 'Q8b', 'B5'),
        ].compact
        assessment_answers.merge!(average_utilization_rate: utilization_values.sum / utilization_values.count.to_f)
      end

      assessment_answers.merge!(
        {
          status: 'pre-filled',
        },
      )

      update(assessment_answers)
    end

    def send_email_to_secondary_reviewer
      BostonProjectScorecard::ScorecardMailer.scorecard_ready(self).deliver_later
    end

    def send_email_to_owner
      BostonProjectScorecard::ScorecardMailer.scorecard_complete(self).deliver_later
    end

    private def apr_report
      filter = ::Filters::HudFilterBase.new(user_id: user_id)
      if project_id.present?
        project_ids = [project_id]
      else
        project_ids = GrdaWarehouse::ProjectGroup.viewable_by(User.find(user_id)).find(project_group_id).projects.pluck(:id)
      end
      filter.set_from_params(
        {
          start: start_date,
          end: end_date,
          project_ids: project_ids,
        },
      )
      questions = [
        'Question 5',
        'Question 6',
        'Question 8',
        'Question 19',
        'Question 22',
        'Question 23',
      ]
      generator = HudApr::Generators::Apr::Fy2021::Generator
      apr = HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: questions)
      generator.new(apr).run!(email: false, manual: false)

      apr
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_client_ids(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.pluck(:client_id)
    end
  end
end
