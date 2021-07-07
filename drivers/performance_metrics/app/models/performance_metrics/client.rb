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
      spm_leaver(period).where("#{period}_period_days_to_return" => 1..731)
    end

    scope :did_not_return_in_two_years, ->(period) do
      spm_leaver(period).where(
        arel_table["#{period}_period_days_to_return"].gt(731).
        or(arel_table["#{period}_period_days_to_return"].eq(nil)),
      )
    end

    scope :caper_leaver, ->(period) do
      served(period).where("#{period}_period_caper_leaver" => true)
    end

    scope :spm_leaver, ->(period) do
      where("#{period}_period_spm_leaver" => true)
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

    def self.detail_headers
      cols = [
        'client_id',
        'first_name',
        'last_name',
        'include_in_current_period',
        'current_period_age',
        'current_period_earned_income_at_start',
        'current_period_earned_income_at_exit',
        'current_period_other_income_at_start',
        'current_period_other_income_at_exit',
        'current_caper_leaver',
        'current_period_days_in_es',
        'current_period_days_in_rrh',
        'current_period_days_in_psh',
        'current_period_days_to_return',
        'current_period_spm_leaver',
        'current_period_first_time',
        'current_period_reentering',
        'current_period_in_outflow',
        'current_period_entering_housing',
        'current_period_inactive',
        'current_period_caper_id',
        'current_period_spm_id',
        'include_in_prior_period',
        'prior_period_age',
        'prior_period_earned_income_at_start',
        'prior_period_earned_income_at_exit',
        'prior_period_other_income_at_start',
        'prior_period_other_income_at_exit',
        'prior_caper_leaver',
        'prior_period_days_in_es',
        'prior_period_days_in_rrh',
        'prior_period_days_in_psh',
        'prior_period_days_to_return',
        'prior_period_spm_leaver',
        'prior_period_first_time',
        'prior_period_reentering',
        'prior_period_in_outflow',
        'prior_period_entering_housing',
        'prior_period_inactive',
        'prior_period_caper_id',
        'prior_period_spm_id',
      ].freeze
      cols.map do |col|
        [
          col,
          PerformanceMetrics::Client.human_attribute_name(col),
        ]
      end.to_h
    end
  end
end
