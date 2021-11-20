###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting::Calculators
  class PatientSdhRiskScore
    def initialize(medicaid_ids)
      @medicaid_ids = medicaid_ids
    end

    def to_map
      @to_map ||= ClaimsReporting::MemberRoster.
        where(member_id: @medicaid_ids).
        pluck(:member_id, :normalized_risk_score).
        to_h
    end

    def self.dashboard_sort_options
      {
        column: 'sdh_risk_score',
        direction: :desc,
        title: 'Risk Score (High to Low)',
      }
    end

    def sort_order(column, direction)
      return unless column == 'sdh_risk_score'

      order = to_map.sort_by { |_, v| v.to_f }
      order.reverse! if direction == :desc

      { medicaid_id: order.to_h.keys }
    end
  end
end
