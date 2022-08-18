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
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :client_id

    scope :in_period, ->(period) do
      where(period: period)
    end

    scope :served_in_period, ->(period) do
      in_period(period).where(q5a_b1: true)
    end

    scope :hoh, -> do
      where(head_of_household: true)
    end

    scope :literally_homeless_at_entry, -> do
      where(literally_homeless_at_entry_query)
    end

    scope :literally_homeless, -> do
      where(literally_homeless_at_entry_query.or(literally_homeless_during_enrollment_query))
    end

    scope :not_literally_homeless, -> do
      where.not(literally_homeless_at_entry_query.or(literally_homeless_during_enrollment_query))
    end

    scope :diverted, -> do
      where(diversion_event: true)
    end

    scope :successfully_diverted, -> do
      diverted.where(diversion_successful: true)
    end

    scope :veteran, -> do
      where(veteran: true)
    end

    scope :adult_and_child_households, -> do
      where(household_type: :adults_and_children).hoh
    end

    scope :adult_only_households, -> do
      where(household_type: :adults_only).hoh
    end

    scope :child_only_households, -> do
      where(household_type: :children_only).hoh
    end

    scope :youth_only_households, -> do
      # Unclear why, but active record extended isn't working here
      where(household_type: :adults_only).where('household_ages <@ json_build_array(?)::jsonb', (18..24).to_a).hoh
    end

    scope :unknown_households, -> do
      where(household_type: :unknown).hoh
    end

    scope :chronically_homeless_at_entry, -> do
      where(chronically_homeless_at_entry: true)
    end

    scope :children, -> do
      where(reporting_age: 0..17)
    end

    scope :over_55, -> do
      where(reporting_age: 55..105)
    end

    scope :dv_survivor, -> do
      where(dv_survivor: true)
    end

    scope :client_lgbtq, -> do
      where(client_lgbtq: true)
    end

    scope :lgbtq_household_members, -> do
      where(lgbtq_household_members: true).hoh
    end

    scope :race_am_ind_ak_native, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_am_ind_ak_native)
    end
    scope :race_asian, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_asian)
    end
    scope :race_black_af_american, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_black_af_american)
    end
    scope :race_native_hi_other_pacific, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_native_hi_other_pacific)
    end
    scope :race_white, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_white)
    end
    scope :multi_racial, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.multi_racial)
    end

    scope :non_hispanic, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.where(Ethnicity: 0))
    end
    scope :hispanic, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.where(Ethnicity: 1))
    end

    scope :female, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_female)
    end
    scope :male, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_male)
    end
    scope :agender, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.no_single_gender)
    end
    scope :transgender, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_transgender)
    end
    scope :questioning, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.questioning)
    end

    # FIXME eventually.  This would be much better if we could figure out how to query the events column
    # something like and events @> '{"event": "13"}'
    def self.with_event_type(event_type)
      where.not(events: nil).to_a.select { |c| c.events.detect { |e| e['event'] == event_type }.present? }
    end

    def self.literally_homeless_at_entry_query
      arel_table[:prior_living_situation].in(::HUD.homeless_situations(as: :prior)).
        or(arel_table[:los_under_threshold].eq(1).and(arel_table[:previous_street_essh].eq(1)))
    end

    def self.literally_homeless_during_enrollment_query
      arel_table[:cls_literally_homeless].eq(true)
    end

    def self.subpopulations(report)
      pops = {
        'All Clients' => nil,
        'Veterans' => :veteran,
        'Adult and Child Households' => :adult_and_child_households,
        'Adult only Households (> 18)' => :adult_only_households,
        'Child only Households (< 18)' => :child_only_households,
        'Youth only Households (18-24)' => :youth_only_households,
        'Unknown Household Type' => :unknown_households,
        'Chronically Homeless at Entry' => :chronically_homeless_at_entry,
        'Under 18' => :children,
        'Over 55' => :over_55,
      }
      if report.include_supplemental?
        pops['Survivor of Domestic Violence'] = :dv_survivor
        pops['LGBTQ'] = :client_lgbtq
        pops['Household LGBTQ'] = :lgbtq_household_members
      end
      race_pops = {
        'American Indian, Alaska Native, or Indigenous' => :race_am_ind_ak_native,
        'Asian or Asian American' => :race_asian,
        'Black, African American, or African' => :race_black_af_american,
        'Native Hawaiian or Pacific Islander' => :race_native_hi_other_pacific,
        'White' => :race_white,
        'Multi-Racial' => :multi_racial,
        'Non-Hispanic/Non-Latin(a)(o)(x)' => :non_hispanic,
        'Hispanic/Latin(a)(o)(x)' => :hispanic,
      }
      gender_pops = {
        'Female' => :female,
        'Male' => :male,
        'A gender other than singularly female or male (e.g., non-binary, genderfluid, agender, culturally specific gender)' => :agender,
        'Transgender' => :transgender,
        'Questioning' => :questioning,
      }
      pops = pops.merge(race_pops)
      pops = pops.merge(gender_pops)
      pops
    end
  end
end
