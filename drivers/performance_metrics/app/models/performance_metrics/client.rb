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
      served(period).where("#{period}_period_days_to_return" => 1..731)
    end

    scope :caper_leaver, ->(period) do
      served(period).where("#{period}_period_caper_leaver" => true)
    end

    scope :spm_leaver, ->(period) do
      served(period).where("#{period}_period_spm_leaver" => true)
    end

    scope :entering_housing, ->(period) do
      served(period).where("#{period}_period_entering_housing" => true)
    end

    scope :with_earned_income_at_start, ->(period) do
      served(period).where(arel_table["#{period}_period_earned_income_at_start"].gt(0))
    end

    scope :with_increased_earned_income, ->(period) do
      served(period).where(arel_table["#{period}_period_earned_income_at_start"].lt(arel_table["#{period}_period_earned_income_at_exit"]))
    end

    scope :with_other_income_at_start, ->(period) do
      served(period).where(arel_table["#{period}_period_other_income_at_start"].gt(0))
    end

    scope :with_increased_other_income, ->(period) do
      served(period).where(arel_table["#{period}_period_other_income_at_start"].lt(arel_table["#{period}_period_other_income_at_exit"]))
    end

    scope :in_outflow, ->(period) do
      served(period).where("#{period}_period_in_outflow" => true)
    end

    scope :in_inflow, ->(period) do
      served(period).where(arel_table["#{period}_period_first_time"].eq(true).or(arel_table["#{period}_period_reentering"].eq(true)))
    end

    scope :with_es_stay, ->(period) do
      served(period).where(arel_table["#{period}_period_days_in_es"].gt(0))
    end

    scope :with_rrh_stay, ->(period) do
      served(period).where(arel_table["#{period}_period_days_in_rrh"].gt(0))
    end

    scope :with_psh_stay, ->(period) do
      served(period).where(arel_table["#{period}_period_days_in_psh"].gt(0))
    end

    scope :first_time, ->(period) do
      served(period).where("#{period}_period_first_time" => true)
    end

    scope :reentering, ->(period) do
      served(period).where("#{period}_period_reentering" => true)
    end

    scope :entered_housing, ->(period) do
      served(period).where("#{period}_period_entering_housing" => true)
    end

    scope :inactive, ->(period) do
      served(period).where("#{period}_period_inactive" => true)
    end
  end
end
