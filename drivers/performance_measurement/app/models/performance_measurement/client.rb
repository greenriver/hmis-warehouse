###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Client < GrdaWarehouseBase
    self.table_name = :pm_clients
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :report
    has_many :client_projects, primary_key: [:client_id, :report_id], foreign_key: [:client_id, :report_id]

    def self.column_titles(period: 'reporting')
      {
        'client_id' => 'Warehouse Client ID',
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
