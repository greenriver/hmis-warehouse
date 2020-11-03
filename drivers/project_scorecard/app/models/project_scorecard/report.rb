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

    def locked?(_field, _user)
      # TODO: Implement field access rules
      false
    end

    # include? doesn't work on open ranges, so we do it by hand
    private def in_range?(range, value)
      if range.end.nil?
        value > range.begin
      else
        range.include?(value)
      end
    end

    private def score(value, ten_range, five_range = nil)
      return nil if value.blank?

      if in_range?(ten_range, value)
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
      ].freeze
    end

    def send_email(from)
      # TODO
    end
  end
end
