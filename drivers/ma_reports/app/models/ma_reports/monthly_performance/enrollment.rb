###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::MonthlyPerformance
  class Enrollment < GrdaWarehouseBase
    self.table_name = :ma_monthly_performance_enrollments
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id

    scope :open_between, ->(range) do
      a_t = arel_table
      entry_date = a_t[:entry_date]
      exit_date = a_t[:exit_date]
      # Currently does not count as an overlap if one starts on the end of the other
      where(exit_date.gteq(range.first).or(exit_date.eq(nil)).and(entry_date.lteq(range.last)))
    end

    def self.headers
      {
        client_id: 'Warehouse Client ID',
        personal_id: 'HMIS Personal ID',
        first_name: 'First Name',
        last_name: 'Last Name',
        city: 'City',
        coc_code: 'CoC',
        entry_date: 'Entry Date',
        exit_date: 'Exit Date',
        latest_for_client: 'Most-Recent Enrollment for Client',
        chronically_homeless_at_entry: 'Chronically Homeless at Entry',
        stay_length_in_days: 'Stay Length in Days',
        am_ind_ak_native: HudUtility2024.race('AmIndAKNative'),
        asian: HudUtility2024.race('Asian'),
        black_af_american: HudUtility2024.race('BlackAfAmerican'),
        native_hi_pacific: HudUtility2024.race('NativeHIPacific'),
        white: HudUtility2024.race('White'),
        hispanic_latinaeo: HudUtility2024.race('HispanicLatinaeo'),
        mid_east_n_african: HudUtility2024.race('MidEastNAfrican'),
        man: 'Man',
        woman: 'Woman',
        culturally_specific: 'Culturally Specific Identity (e.g., Two-Spirit)',
        different_identity: 'Different Identity',
        transgender: 'Transgender',
        questioning: 'Questioning',
        non_binary: 'Non-Binary',
        disabling_condition: 'Disabling Condition',
        reporting_age: 'Reporting Age',
        prior_living_situation: 'Prior Living Situation',
        months_homeless_past_three_years: 'Months homeless in the past three years',
        times_homeless_past_three_years: 'Times homeless in the past three years',
      }
    end
  end
end
