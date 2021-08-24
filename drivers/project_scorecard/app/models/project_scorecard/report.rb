###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    acts_as_paranoid
    has_paper_trail

    # Calculations for report sections
    include Header
    include TotalScore
    include ProjectPerformance
    include DataQuality
    include CeParticipation
    include GrantManagementAndFinancials
    include ReviewOnly

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    belongs_to :project_group, class_name: 'GrdaWarehouse::ProjectGroup', optional: true
    belongs_to :user, class_name: 'User'
    belongs_to :apr, class_name: 'HudReports::ReportInstance', optional: true

    has_many :project_contacts, through: :project, source: :contacts
    has_many :organization_contacts, through: :project
    has_many :project_group_project_contacts, through: :project_group, source: :contacts
    has_many :project_group_organization_contacts, through: :project_group, source: :organization_contacts

    def completed?
      status == 'completed'
    end

    def pending?
      status == 'pending'
    end

    def locked?(field, _user)
      # TODO: Implement field access rules for users
      case status
      when 'pending'
        case field
        when :recipient, :subrecipient, :funding_year, :grant_term
          # Allow editing the header while being pre-filled
          false
        else
          true
        end

      when 'pre-filled'
        # Prevent editing the response during initial review
        case field
        when :improvement_plan, :financial_plan
          true
        else
          false
        end

      when 'ready'
        case field
        when :improvement_plan, :financial_plan
          false
        else
          true
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

    def site_monitoring_options
      @site_monitoring_options ||= [
        'No Findings',
        'Findings but Resolved',
        'Finding with no Resolution',
      ].freeze
    end

    def controlled_parameters
      @controlled_parameters ||= [
        :recipient,
        :subrecipient,
        :funding_year,
        :grant_term,
        :utilization_jan,
        :utilization_apr,
        :utilization_jul,
        :utilization_oct,
        :utilization_proposed,
        :chronic_households_served,
        :total_households_served,
        :total_persons_served,
        :total_persons_with_positive_exit,
        :total_persons_exited,
        :excluded_exits,
        :average_los_leavers,
        :percent_increased_employment_income_at_exit,
        :percent_increased_other_cash_income_at_exit,
        :percent_returns_to_homelessness,
        :percent_pii_errors,
        :percent_ude_errors,
        :percent_income_and_housing_errors,
        :days_to_lease_up,
        :number_referrals,
        :accepted_referrals,
        :funds_expended,
        :amount_awarded,
        :months_since_start,
        :budget_plus_match,
        :prior_amount_awarded,
        :prior_funds_expended,
        :pit_participation,
        :coc_meetings,
        :coc_meetings_attended,
        :site_monitoring,
        :total_ces_referrals,
        :accepted_ces_referrals,
        :clients_with_vispdats,
        :average_vispdat_score,
        :improvement_plan,
        :financial_plan,
        :expansion_year,
        :special_population_only,
        :project_less_than_two,
        :geographic_location,
      ].freeze
    end

    def project_name
      return project.name if project.present?

      project_group.name
    end

    def key_project
      return project if project.present?

      candidate = project_group.projects.detect(&:rrh?)
      candidate = project_group.projects.detect(&:psh?) if candidate.blank?
      candidate = project_group.projects.detect(&:sh?) if candidate.blank?
      candidate = project_group.projects.first if candidate.blank?
      candidate
    end

    def title
      "#{project_name} Project Scorecard"
    end

    def url
      project_scorecard_warehouse_reports_scorecard_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def run_and_save!
      update(started_at: Time.current)

      previous = if project_id.present?
        self.class.where(project_id: project_id).
          where.not(id: id).
          order(id: :desc).
          first
      else
        self.class.where(project_group_id: project_group_id).
          where.not(id: id).
          order(id: :desc).
          first
      end
      assessment_answers = {}

      if RailsDrivers.loaded.include?(:hud_apr)
        # Generate APR
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
          'Question 26',
        ]
        generator = HudApr::Generators::Apr::Fy2020::Generator
        apr = HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: questions)
        generator.new(apr).run!(email: false)

        assessment_answers.merge!(
          {
            apr_id: apr.id,

            utilization_jan: answer(apr, 'Q8b', 'B2'),
            utilization_apr: answer(apr, 'Q8b', 'B3'),
            utilization_jul: answer(apr, 'Q8b', 'B4'),
            utilization_oct: answer(apr, 'Q8b', 'B5'),

            chronic_households_served: answer(apr, 'Q26a', 'B2'),
            total_households_served: answer(apr, 'Q26a', 'B6'),

            total_persons_served: answer(apr, 'Q5a', 'B1'),
            total_persons_with_positive_exit: answer(apr, 'Q23c', 'B44'),
            total_persons_exited: answer(apr, 'Q23c', 'B43'),
            excluded_exits: answer(apr, 'Q23c', 'B45'),

            average_los_leavers: answer(apr, 'Q22b', 'B2'),

            percent_pii_errors: answer(apr, 'Q6a', 'F8').to_f * 100,

            days_to_lease_up: answer(apr, 'Q22c', 'B11'),
          },
        )

        # Percent increased income calculations

        leavers_or_annual_expected_with_employment_income = answer(apr, 'Q19a1', 'H2') + answer(apr, 'Q19a2', 'H2')
        increased_employment_income = answer(apr, 'Q19a1', 'I2') + answer(apr, 'Q19a2', 'I2')
        percent_increased_employment_income_at_exit = percentage(increased_employment_income / leavers_or_annual_expected_with_employment_income.to_f)

        leavers_or_annual_expected_with_other_income = answer(apr, 'Q19a1', 'H4') + answer(apr, 'Q19a2', 'H4')
        increased_other_income = answer(apr, 'Q19a1', 'I4') + answer(apr, 'Q19a2', 'I4')
        percent_increased_other_cash_income_at_exit = percentage(increased_other_income / leavers_or_annual_expected_with_other_income.to_f)

        # Data quality calculations
        total_hoh_served = answer(apr, 'Q5a', 'B14')

        # need unique count of client_ids not, sum of counts since someone might appear more than once
        total_ude_errors = (2..6).map { |row| answer_client_ids(apr, 'Q6b', 'B' + row.to_s) }.flatten.uniq.count
        percent_ude_errors = percentage(total_ude_errors / total_hoh_served.to_f)

        total_income_and_housing_errors = (2..5).map { |row| answer_client_ids(apr, 'Q6c', 'B' + row.to_s) }.flatten.uniq.count
        percent_income_and_housing_errors = percentage(total_income_and_housing_errors / total_hoh_served.to_f)

        assessment_answers.merge!(
          {
            percent_increased_employment_income_at_exit: percent_increased_employment_income_at_exit,
            percent_increased_other_cash_income_at_exit: percent_increased_other_cash_income_at_exit,
            percent_ude_errors: percent_ude_errors,
            percent_income_and_housing_errors: percent_income_and_housing_errors,
          },
        )
      end

      assessment_answers.merge!(
        {
          percent_returns_to_homelessness: percent_returns_to_homelessness_from_spm(project_ids),
          clients_with_vispdats: clients_with_vispdats_fom_hmis(project_ids).count,
          average_vispdat_score: average_vispdat_score_fom_hmis(project_ids),
        },
      )

      assessment_answers.merge!(
        {
          amount_awarded: previous&.amount_awarded,
          budget_plus_match: previous&.budget_plus_match,
          prior_amount_awarded: previous&.prior_amount_awarded,
          status: 'pre-filled',
        },
      )
      update(assessment_answers)
    end

    def send_email_to_contacts
      contacts.index_by(&:email).each_value do |contact|
        ProjectScorecard::ScorecardMailer.scorecard_ready(self, contact).deliver_later
      end
    end

    def contacts
      @contacts ||= (project_contacts + organization_contacts + project_group_project_contacts + project_group_organization_contacts).uniq
    end

    def send_email_to_owner
      ProjectScorecard::ScorecardMailer.scorecard_complete(self).deliver_later
    end

    private def percent_returns_to_homelessness_from_spm(project_ids)
      return unless RailsDrivers.loaded.include?(:hud_spm_report)

      # Generate SPM
      filter = ::Filters::HudFilterBase.new(user_id: user_id)
      filter.set_from_params(
        {
          start: start_date,
          end: end_date,
          project_ids: project_ids,
        },
      )
      questions = [
        'Measure 2',
      ]
      generator = HudSpmReport::Generators::Fy2020::Generator
      spm = HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: questions)
      generator.new(spm).run!(email: false)

      number_of_exits = answer(spm, '2', 'B7')
      number_of_returns = answer(spm, '2', 'I7')

      return nil if number_of_exits.blank? || number_of_exits.zero?

      return percentage(number_of_returns / number_of_exits.to_f)
    end

    private def clients_with_vispdats_fom_hmis(project_ids)
      GrdaWarehouse::Hud::Client.
        joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.vispdat).
        where(id: GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          open_between(start_date: start_date, end_date: end_date).
          in_project(project_ids).
          select(:client_id)).
        distinct
    end

    private def average_vispdat_score_fom_hmis(project_ids)
      clients_with_vispdats_fom_hmis(project_ids).
        merge(GrdaWarehouse::HmisForm.within_range(start_date..end_date)).
        average(:vispdat_total_score)
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_client_ids(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.pluck(:client_id)
    end

    private def percentage(value)
      return 0 if value.nan?

      (value * 100).to_i
    end
  end
end
