###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
        am_ind_ak_native: HudUtility.race('AmIndAKNative'),
        asian: HudUtility.race('Asian'),
        black_af_american: HudUtility.race('BlackAfAmerican'),
        native_hi_pacific: HudUtility.race('NativeHIPacific'),
        white: HudUtility.race('White'),
        ethnicity: 'Ethnicity',
        male: 'Male',
        female: 'Female',
        transgender: 'Transgender',
        questioning: 'Questioning',
        no_single_gender: 'A gender other than singularly female or male (e.g., non-binary, genderfluid, agender, culturally specific gender)',
        disabling_condition: 'Disabling Condition',
        reporting_age: 'Reporting Age',
        prior_living_situation: 'Prior Living Situation',
        months_homeless_past_three_years: 'Months homeless in the past three years',
        times_homeless_past_three_years: 'Times homeless in the past three years',
      }
    end
  end
end
