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
    # TODO: includes
    include Header
    include TotalScore

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    belongs_to :project_group, class_name: 'GrdaWarehouse::ProjectGroup', optional: true
    belongs_to :user, class_name: 'User', optional: true
    belongs_to :apr, class_name: 'HudReports::ReportInstance', optional: true

    has_many :project_contacts, through: :project, source: :contacts
    has_many :organization_contacts, through: :project
    has_many :project_group_project_contacts, through: :project_group, source: :contacts
    has_many :project_group_organization_contacts, through: :project_group, source: :organization_contacts

    scope :started_between, ->(start_date:, end_date:) do
      where(started_at: (start_date..end_date))
    end

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

    private def percentage(value)
      return 0 if value.nan?
      return 0 if value.infinite?

      (value * 100).to_i
    end

    def controlled_parameters
      @controlled_parameters ||= [
        :project_type,
        :period_start_date,
        :period_end_date,
        :secondary_reviewer,
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
      ].freeze
    end

    def project_name
      return project.name if project.present?

      project_group.name
    end

    def title
      'MA-500 Boston Continuum of Care FY21 Renewal Project Scoring Tool'
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
      assessment_answers = {}

      assessment_answers.merge!(
        {
          apr_id: apr&.id,
          project_type: project_type,
          status: 'pre-filled',
        },
      )

      update(assessment_answers)
    end

    def send_email_to_contacts
      contacts.index_by(&:email).each_value do |contact|
        BostonProjectScorecard::ScorecardMailer.scorecard_ready(self, contact).deliver_later
      end
    end

    def contacts
      @contacts ||= (project_contacts + organization_contacts + project_group_project_contacts + project_group_organization_contacts).uniq
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
