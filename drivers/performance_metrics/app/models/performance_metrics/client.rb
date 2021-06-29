###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMetrics
  class Client < GrdaWarehouseBase
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id

    scope :served, ->(period) do
      where("include_in_#{period}_period" => true)
    end

    scope :returned_in_two_years, ->(period) do
      served(periods).where("#{period}_period_days_to_return" => 731..Float::INFINITY)
    end
  end
end
