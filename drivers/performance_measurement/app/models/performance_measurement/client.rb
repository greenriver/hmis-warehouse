###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Client < GrdaWarehouseBase
    include Filter::FilterScopes # for race-ethnicity combination scopes
    self.table_name = :pm_clients
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :report
    has_many :client_projects, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id]
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', optional: true, foreign_key: :client_id

    # Gender scopes
    scope :gender_woman, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_woman)
    end

    scope :gender_man, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_man)
    end

    scope :gender_non_binary, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_non_binary)
    end

    scope :gender_questioning, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_questioning)
    end

    scope :gender_transgender, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_transgender)
    end

    scope :gender_unknown, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_unknown)
    end

    scope :gender_culturally_specific, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_culturally_specific)
    end

    scope :gender_different_identity, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.gender_different_identity)
    end

    # Race scopes
    scope :race_am_ind_ak_native, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_am_ind_ak_native)
    end

    scope :race_asian, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_asian)
    end

    scope :race_black_af_american, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_black_af_american)
    end

    scope :race_native_hi_pacific, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_native_hi_pacific)
    end

    scope :race_white, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_white)
    end

    scope :race_mid_east_n_african, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_mid_east_n_african)
    end

    scope :race_none, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_none)
    end

    scope :race_doesnt_know, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_doesnt_know)
    end

    scope :race_refused, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_refused)
    end

    scope :race_not_collected, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_not_collected)
    end

    # Ethnicity Scopes
    scope :ethnicity_hispanic_latinaeo, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_hispanic_latinaeo)
    end

    scope :ethnicity_non_hispanic_latinaeo, -> do
      joins(:source_client).merge(GrdaWarehouse::Hud::Client.race_not_hispanic_latinaeo)
    end

    # Race Ethnicity Combination Scopes
    def report_scope_source # needed for filter scopes
      self.class
    end

    private def join_clients_method
      :source_client
    end

    scope :race_ethnicity_am_ind_ak_native, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :AmIndAKNative, false))
    end

    scope :race_ethnicity_am_ind_ak_native_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :AmIndAKNative, true))
    end

    scope :race_ethnicity_asian, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :Asian, false))
    end

    scope :race_ethnicity_asian_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :Asian, true))
    end

    scope :race_ethnicity_black_af_american, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :BlackAfAmerican, false))
    end

    scope :race_ethnicity_black_af_american_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :BlackAfAmerican, true))
    end

    scope :race_ethnicity_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :HispanicLatinaeo, true))
    end

    scope :race_ethnicity_mid_east_n_african, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :MidEastNAfrican, false))
    end

    scope :race_ethnicity_mid_east_n_african_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :MidEastNAfrican, true))
    end

    scope :race_ethnicity_native_hi_pacific, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :NativeHIPacific, false))
    end

    scope :race_ethnicity_native_hi_pacific_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :NativeHIPacific, true))
    end

    scope :race_ethnicity_white, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :White, false))
    end

    scope :race_ethnicity_white_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :White, true))
    end

    scope :race_ethnicity_multi_racial, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :MultiRacial, false))
    end

    scope :race_ethnicity_multi_racial_hispanic_latinaeo, -> do
      joins(:source_client).merge(new.race_ethnicity_alternative(GrdaWarehouse::Hud::Client, :MultiRacial, true))
    end

    scope :race_ethnicity_race_none, -> do
      race_none
    end

    def self.column_titles(period: 'reporting')
      {
        'client_id' => 'Warehouse Client ID',
        'source_client_personal_ids' => 'Source Client Personal IDs',
        'dob' => 'DOB',
        'veteran' => 'Veteran Status',
        "#{period}_age" => 'Age for Report',
        "#{period}_hoh" => 'Head of Household?',
        "#{period}_stayer" => 'Stayer?',
        "#{period}_leaver" => 'Leaver?',
        "#{period}_first_time" => 'First Time?',
        "#{period}_days_in_es_bed" => 'Days in ES',
        "#{period}_days_in_sh_bed" => 'Days in SH',
        "#{period}_days_in_so_bed" => 'Days in SO',
        "#{period}_days_in_th_bed" => 'Days in TH',
        "#{period}_days_homeless_es_sh_th" => 'Days Homeless in ES, SH, TH',
        "#{period}_days_homeless_es_sh_th_ph" => 'Days Homeless in ES, SH, TH, PH',
        "#{period}_days_to_return" => 'Days to Return',
        "#{period}_days_in_es_bed_details" => 'ES Details',
        "#{period}_days_in_sh_bed_details" => 'SH Details',
        "#{period}_days_in_so_bed_details" => 'SO Details',
        "#{period}_days_in_th_bed_details" => 'TH Details',

        "#{period}_days_in_es_bed_in_period" => 'ES Days in Period',
        "#{period}_days_in_sh_bed_in_period" => 'SH Days in Period',
        "#{period}_days_in_so_bed_in_period" => 'SO Days in Period',
        "#{period}_days_in_th_bed_in_period" => 'TH Days in Period',
        # "#{period}_days_referral_to_ph_entry" => '',
        "#{period}_days_homeless_before_move_in" => 'Days Before Move-In',
        "#{period}_days_in_es_bed_details_in_period" => 'ES Details in Period',
        "#{period}_days_in_sh_bed_details_in_period" => 'SH Details in Period',
        "#{period}_days_in_so_bed_details_in_period" => 'SO Details in Period',
        "#{period}_days_in_th_bed_details_in_period" => 'TH Details in Period',
        "#{period}_days_in_homeless_bed" => 'Homeless Days',
        "#{period}_days_in_homeless_bed_details" => 'Homeless Days Details',
        "#{period}_days_in_homeless_bed_in_period" => 'Homeless Days in Period',
        "#{period}_days_in_homeless_bed_details_in_period" => 'Homeless Days in Period Details',
        "#{period}_served_in_so" => 'Served in SO?',
        "#{period}_so_es_sh_th_return_6_mo" => 'Return within 6 months?',
        "#{period}_so_es_sh_th_return_2_yr" => 'Return within 2 years?',
        "#{period}_moved_in_stayer" => 'Stayer with Move-In?',
        "#{period}_income_stayer" => 'Income for Stayer',
        "#{period}_income_leaver" => 'Income for Leaver',
        "#{period}_increased_income" => 'Income Increased?',
        "#{period}_prior_living_situation" => 'Prior Living Situation',
        "#{period}_prior_destination" => 'Destination Prior to Return',
        "#{period}_destination" => 'Destination',
        "#{period}_so_destination" => 'Destination from SO',
        "#{period}_moved_in_destination" => 'Destination after Move-In',
        "#{period}_es_sh_th_rrh_destination" => 'ES, SH, TH, RRH Destination',
        "#{period}_so_es_sh_th_2_yr_permanent_dest" => 'SO, ES, SH, TH, Permanent Destination',
        "#{period}_current_project_types" => 'Project Types for Period',
        "#{period}_prior_project_types" => 'Prior Project Types',
        "#{period}_served_on_pit_date" => 'Served on PIT Date',
        "#{period}_served_on_pit_date_sheltered" => 'Sheltered on PIT Date',
        "#{period}_served_on_pit_date_unsheltered" => 'Unsheltered on PIT Date',
        "#{period}_pit_project_id" => 'Project ID for PIT',
        "#{period}_pit_project_type" => 'Project Type for PIT',
        "#{period}_days_in_ce" => 'Days in CE',
        "#{period}_days_ce_to_referral" => 'Days in CE Before Referral',
        "#{period}_days_ce_to_assessment" => 'Days in CE Before Assessment',
        "#{period}_days_since_assessment" => 'Days since Assessment',
        "#{period}_ce_enrollment" => 'CE Enrollment?',
        "#{period}_ce_diversion" => 'CE Diversion?',
        "#{period}_ce_assessment_score" => 'CE Assessment Score',
        "#{period}_prevention_tool_score" => 'Prevention Tool Score',
      }
    end
  end
end
