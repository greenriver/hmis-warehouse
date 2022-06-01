###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class Client < GrdaWarehouseBase
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :report

    scope :in_period, ->(period) do
      where(period: period)
    end

    scope :served_in_period, ->(period) do
      in_period(period).where(q5a_b1: true)
    end

    scope :literally_homeless_at_entry, -> do
      where(
        arel_table[:prior_living_situation].in(::HUD.homeless_situations(as: :prior)).
        or(arel_table[:los_under_threshold].eq(1).and(arel_table[:previous_street_essh].eq(1))),
      )
    end
  end
end
