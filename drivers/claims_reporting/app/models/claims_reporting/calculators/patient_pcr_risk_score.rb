###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting::Calculators
  class PatientPcrRiskScore
    def initialize(medicaid_ids = [], date_range: Date.current.beginning_of_year..Date.current.end_of_year)
      @medicaid_ids = medicaid_ids
      @date_range = date_range
    end

    def to_map
      @to_map ||= {}.tap do |result|
        @medicaid_ids.each do |medicaid_id|
          member = member_by_member_id(medicaid_id)
          next unless member.present?

          claims = medical_claims_by_member_id(medicaid_id)
          stay_claims = claims.select do |claim|
            claim.discharge_date.present? && measurement_year.cover?(claim.discharge_date) && (
              (Hl7.in_set?('Inpatient Stay', claim) && !Hl7.in_set?('Nonacute Inpatient Stay', claim)) ||
                Hl7.in_set?('Observation Stay', claim)
            )
          end.sort_by(&:service_start_date)
          result[medicaid_id] = ihs_risk_adjustment(member, stay_claims, claims)&.dig(:expected_readmit_rate)&.round(4)
        end
      end
    end

    def self.dashboard_sort_options
      {
        column: 'pcr_risk_score',
        direction: :desc,
        title: 'Estimated Readmission Risk',
      }
    end

    def sort_order(column, direction)
      return unless column == 'pcr_risk_score'

      order = to_map.sort_by { |_, v| v.to_f }
      order.reverse! if direction == :desc

      { medicaid_id: order.to_h.keys }
    end

    def member_by_member_id(member_id)
      @member_by_member_id ||= ::ClaimsReporting::MemberRoster.
        where(member_id: @medicaid_ids).
        select(
          :id,
          :member_id,
          :date_of_birth,
          :sex,
        ).
        index_by(&:member_id)

      @member_by_member_id[member_id]
    end

    def medical_claims_by_member_id(member_id)
      @medical_claims_by_member_id ||= ::ClaimsReporting::MedicalClaim.
        joins(:member_roster).
        where(member_id: @medicaid_ids).
        service_in(@date_range).
        group_by(&:member_id)

      @medical_claims_by_member_id[member_id] || []
    end

    def measurement_year
      @date_range.max.beginning_of_year .. @date_range.max.end_of_year
    end

    def ihs_risk_adjustment(member, stay_claims, claims)
      @pcr_risk_adjustment_calculator ||= pcr_risk_adjustment_calculator
      return unless @pcr_risk_adjustment_calculator

      # See https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
      # ClaimsReporting::Calculators::PcrRiskAdjustment

      discharge_date = stay_claims.last&.discharge_date
      discharge_dx_code = stay_claims.first&.dx_1

      # > Step 1
      # > Identify all diagnoses for encounters during the classification period. Include the following when identifying encounters:
      comorb_dx_codes = Set.new
      claims.each do |c|
        # > • Outpatient visits (Outpatient Value Set).
        # > • Telephone visits (Telephone Visits Value Set)
        # > • Observation visits (Observation Value Set).
        # > • ED visits (ED Value Set).
        # > • Inpatient events:
        # > – Nonacute inpatient encounters (Nonacute Inpatient Value Set).
        # > – Acute inpatient encounters (Acute Inpatient Value Set).
        # > – Acute and nonacute inpatient discharges (Inpatient Stay Value Set).

        # > Use the date of service for outpatient, observation and ED visits. Use the discharge date for inpatient events.
        date = if Hl7.in_set?('Outpatient', c) ||
          Hl7.in_set?('Telephone Visits', c) ||
          Hl7.in_set?('Observation', c)

          c.service_start_date
        elsif Hl7.in_set?('ED', c) ||
          Hl7.in_set?('Nonacute Inpatient', c) ||
          Hl7.in_set?('Acute Inpatient', c)

          c.discharge_date
        end

        next unless date.present? && measurement_year.cover?(date)

        comorb_dx_codes += c.dx_codes
      end
      # > Exclude the primary discharge diagnosis on the IHS.
      comorb_dx_codes -= [discharge_dx_code]

      # > Step 3 Assign each diagnosis to a comorbid Clinical Condition (CC)
      # > category using Table CC— Comorbid. If the code appears more than once
      # > in Table CC—Comorbid, it is assigned to multiple CCs.
      # >All digits must match
      # > exactly when mapping diagnosis codes to the comorbid CCs.
      comorb_cc_codes = comorb_dx_codes.map do |dx_code|
        @pcr_risk_adjustment_calculator.cc_mapping[dx_code]
      end.compact

      # > Exclude all diagnoses that cannot be assigned to a comorbid CC category. For
      # > members with no qualifying diagnoses from face-to-face encounters,
      # > skip to the Risk Adjustment Weighting section.
      return unless comorb_cc_codes.any?

      had_surgery = stay_claims.any? do |c|
        Hl7.in_set?('Surgery Procedure', c)
      end
      observation_stay = stay_claims.any? do |c|
        Hl7.in_set?('Observation Stay', c)
      end

      @pcr_risk_adjustment_calculator.process_ihs(
        age: GrdaWarehouse::Hud::Client.age(dob: member.date_of_birth, date: discharge_date),
        gender: member.sex, # they mean biological sex
        observation_stay: observation_stay,
        had_surgery: had_surgery,
        discharge_dx_code: discharge_dx_code,
        comorb_dx_codes: comorb_dx_codes,
      )
    end

    private def pcr_risk_adjustment_calculator
      ::ClaimsReporting::Calculators::PcrRiskAdjustment.new
    rescue StandardError => e
      logger.warn { "PcrRiskAdjustment calculator is unavailable: #{e.message}" }
      nil
    end
  end
end
