###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectScorecard
  class Report < GrdaWarehouseBase
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

    has_many :project_contacts, through: :project, source: :contacts
    has_many :organization_contacts, through: :project

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
        false

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
        :pit_participation,
        :coc_meetings,
        :coc_meetings_attended,
        :improvement_plan,
        :financial_plan,
      ].freeze
    end

    def notify_requester
      return unless user.present?

      ProjectScorecard::ScorecardMailer.scorecard_prefilled(self, user).deliver
    end

    def send_email
      update(status: 'ready')
      contacts = project_contacts + organization_contacts
      contacts.index_by(&:email).values.each do |contact|
        ProjectScorecard::ScorecardMailer.scorecard_ready(self, contact).deliver
      end
    end
  end
end
