###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CohortColumnOption < GrdaWarehouseBase
    validates_presence_of :cohort_column, :value

    def cohort_columns
      @cohort_columns ||= GrdaWarehouse::Cohort.available_columns.select do |m|
        m.is_a? CohortColumns::Select
      end
    end

    def self.add_initial_cohort_column_options
      where(cohort_column: :chapter_115, value: '', active: 1).first_or_create
      where(cohort_column: :chapter_115, value: 'Receiving', active: 1).first_or_create
      where(cohort_column: :chapter_115, value: 'Eligible', active: 1).first_or_create
      where(cohort_column: :chapter_115, value: 'Ineligible', active: 1).first_or_create

      where(cohort_column: :criminal_record_status, value: '', active: 1).first_or_create
      where(cohort_column: :criminal_record_status, value: 'Open-Gather additional documentation', active: 1).first_or_create
      where(cohort_column: :criminal_record_status, value: 'Outstanding Warrant', active: 1).first_or_create
      where(cohort_column: :criminal_record_status, value: 'Clear', active: 1).first_or_create
      where(cohort_column: :criminal_record_status, value: 'Needs Mitigation', active: 1).first_or_create
      where(cohort_column: :criminal_record_status, value: 'Mitigated', active: 1).first_or_create

      where(cohort_column: :destination, value: '', active: 1).first_or_create
      where(cohort_column: :destination, value: 'CoC', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Deceased', active: 1).first_or_create
      where(cohort_column: :destination, value: 'DMH Group Home', active: 1).first_or_create
      where(cohort_column: :destination, value: 'DMH Rental Assistance', active: 1).first_or_create
      where(cohort_column: :destination, value: 'DMH Safe Haven', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Institutional Setting: Specify in Notes', active: 1).first_or_create
      where(cohort_column: :destination, value: 'MRVP', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Long Term Medical Care Facility - Nursing Home/Respite', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Other: Must Specify in Notes', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Paul Sullivan Housing', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Private Market', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Project Based Voucher', active: 1).first_or_create
      where(cohort_column: :destination, value: 'Public Housing', active: 1).first_or_create
      where(cohort_column: :destination, value: 'SSVF', active: 1).first_or_create
      where(cohort_column: :destination, value: 'VASH', active: 1).first_or_create

      where(cohort_column: :document_ready, value: '', active: 1).first_or_create
      where(cohort_column: :document_ready, value: 'Precontemplative', active: 1).first_or_create
      where(cohort_column: :document_ready, value: 'HAN Obtained', active: 1).first_or_create
      where(cohort_column: :document_ready, value: 'Limited CAS Signed', active: 1).first_or_create
      where(cohort_column: :document_ready, value: 'Disability Verification Obtained', active: 1).first_or_create

      where(cohort_column: :housing_opportunity, value: '', active: 1).first_or_create
      where(cohort_column: :housing_opportunity, value: 'CAS', active: 1).first_or_create
      where(cohort_column: :housing_opportunity, value: 'Non-CAS', active: 1).first_or_create

      where(cohort_column: :housing_track_enrolled, value: '', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'CoC', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'ESG RRH', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'Inactive', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'Other - in notes', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'RRHHI', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'SSVF - NECHV', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'SSVF - VOA', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'VASH', active: 1).first_or_create
      where(cohort_column: :housing_track_enrolled, value: 'VWH', active: 1).first_or_create

      where(cohort_column: :housing_track_suggested, value: '', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'CoC', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'ESG RRH', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Other - in notes', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'RRHHI', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'SSVF - NECHV', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'SSVF - VOA', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'VASH', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'VWH', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'RRH', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Safe Haven', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Chronic Working Group', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'DMH Group Home', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'DMH Rental Assistance', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'DMH Safe Haven', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Family Reunification', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Institutional Setting: Specify in Notes', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Long Term Medical Care Facility - Nursing Home/Respite', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Mainstream affordable housing', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'MRVP or Section 8', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Other:Must Specify in Notes', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Permanent Supportive Housing', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Private Market - No subsidy or RRH', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Private Market - RRH', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Public Housing or Project Based Voucher', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'SSVF', active: 1).first_or_create
      where(cohort_column: :housing_track_suggested, value: 'Veterans Working Group', active: 1).first_or_create

      where(cohort_column: :legal_barriers, value: 'Legal Barriers', active: 1).first_or_create
      where(cohort_column: :legal_barriers, value: 'CORI', active: 1).first_or_create
      where(cohort_column: :legal_barriers, value: 'SORI', active: 1).first_or_create
      where(cohort_column: :legal_barriers, value: 'Wage Garnishments', active: 1).first_or_create
      where(cohort_column: :legal_barriers, value: 'State Only', active: 1).first_or_create

      where(cohort_column: :location_type, value: '', active: 1).first_or_create
      where(cohort_column: :location_type, value: 'Sheltered', active: 1).first_or_create
      where(cohort_column: :location_type, value: 'Unsheltered', active: 1).first_or_create
      where(cohort_column: :location_type, value: 'Institution less than 90 days', active: 1).first_or_create
      where(cohort_column: :location_type, value: 'Unknown/Missing', active: 1).first_or_create

      where(cohort_column: :not_a_vet, value: '', active: 1).first_or_create
      where(cohort_column: :not_a_vet, value: 'Unchecked in HMIS', active: 1).first_or_create

      where(cohort_column: :primary_housing_track_suggested, value: '', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'CoC', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'DMH Group Home', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'DMH Rental Assistance', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'DMH Safe Haven', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Family Reunification', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Institutional Setting: Specify in Notes', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Long Term Medical Care Facility - Nursing Home/Respite', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Mainstream affordable housing', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'MRVP or Section 8', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Other: Must Specify in Notes', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Permanent Supportive Housing', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Private Market - No subsidy or RRH', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Private Market - RRH', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'Public Housing or Project Based Voucher', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'SSVF', active: 1).first_or_create
      where(cohort_column: :primary_housing_track_suggested, value: 'VASH', active: 1).first_or_create

      where(cohort_column: :sensory_impaired , value: '', active: 1).first_or_create
      where(cohort_column: :sensory_impaired , value: 'No', active: 1).first_or_create
      where(cohort_column: :sensory_impaired , value: 'Sight', active: 1).first_or_create
      where(cohort_column: :sensory_impaired , value: 'Hearing', active: 1).first_or_create
      where(cohort_column: :sensory_impaired , value: 'Sight and Hearing', active: 1).first_or_create
      where(cohort_column: :sensory_impaired , value: 'Other: Must be in Notes', active: 1).first_or_create

      where(cohort_column: :st_francis_house , value: '', active: 1).first_or_create
      where(cohort_column: :st_francis_house , value: 'Infrequent Visitor', active: 1).first_or_create
      where(cohort_column: :st_francis_house , value: 'Frequent Visitor', active: 1).first_or_create
      where(cohort_column: :st_francis_house , value: 'Case Management', active: 1).first_or_create

      where(cohort_column: :status, value: '', active: 1).first_or_create
      where(cohort_column: :status, value: 'Chronic', active: 1).first_or_create
      where(cohort_column: :status, value: 'Probable Chronic', active: 1).first_or_create
      where(cohort_column: :status, value: 'At risk 180+ days', active: 1).first_or_create
      where(cohort_column: :status, value: 'At risk 90-179 days', active: 1).first_or_create

      where(cohort_column: :sub_population, value: '', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'Veteran', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'HUES', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'Street sleeper', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'HUES + Street sleeper', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'Veteran + Street sleeper', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'Veteran + HUES', active: 1).first_or_create
      where(cohort_column: :sub_population, value: 'Veteran + HUES + Street sleeper', active: 1).first_or_create

      where(cohort_column: :va_eligible, value: '', active: 1).first_or_create
      where(cohort_column: :va_eligible, value: 'Yes', active: 1).first_or_create
      where(cohort_column: :va_eligible, value: 'No', active: 1).first_or_create
      where(cohort_column: :va_eligible, value: 'No - ADT Only', active: 1).first_or_create
      where(cohort_column: :va_eligible, value: 'No - Discharge', active: 1).first_or_create
      where(cohort_column: :va_eligible, value: "No - Nat'l Guard", active: 1).first_or_create
      where(cohort_column: :va_eligible, value: 'No - Reserves', active: 1).first_or_create
      where(cohort_column: :va_eligible, value: 'No - Time', active: 1).first_or_create

      where(cohort_column: :sleeping_location, value: '', active: 1).first_or_create
      where(cohort_column: :sleeping_location, value: 'Outdoors', active: 1).first_or_create
      where(cohort_column: :sleeping_location, value: 'Shelter', active: 1).first_or_create
      where(cohort_column: :sleeping_location, value: 'Transitional housing', active: 1).first_or_create
      where(cohort_column: :sleeping_location, value: 'Couch surfing', active: 1).first_or_create
      where(cohort_column: :sleeping_location, value: 'Other', active: 1).first_or_create
      where(cohort_column: :sleeping_location, value: 'Unknown', active: 1).first_or_create

      where(cohort_column: :exit_destination, value: '', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Family Reunification', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Market Rate/Rental by Client', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Permanent Supportive Housing', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Public Housing', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Rapid Rehousing', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Treatment', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Transitional Housing', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Moved to Inactive', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Other', active: 1).first_or_create
      where(cohort_column: :exit_destination, value: 'Unknown', active: 1).first_or_create

      where(cohort_column: :lgbtq, value: '', active: 1).first_or_create
      where(cohort_column: :lgbtq, value: 'Yes', active: 1).first_or_create
      where(cohort_column: :lgbtq, value: 'No', active: 1).first_or_create
    end

    def available_cohort_columns
      cohort_columns.map{|c| [c.title, c.column]}.sort_by(&:first).to_h
    end

  end
end
