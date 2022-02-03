###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module ClaimsReporting
  class MedicalClaim < HealthBase
    extend Memoist

    phi_patient :member_id
    belongs_to :patient, foreign_key: :member_id, class_name: 'Health::Patient', primary_key: :medicaid_id, optional: true

    belongs_to :member_roster, primary_key: :member_id, foreign_key: :member_id, optional: true

    scope :service_in, ->(date_range) do
      where(
        arel_table[:service_start_date].lt(date_range.max).
        and(
          arel_table[:service_end_date].gteq(date_range.min).
          or(arel_table[:service_end_date].eq(nil)),
        ),
      )
    end

    # like service_in but using daterange intersection index in postgres which *might* be faster...
    scope :service_overlaps, ->(date_range) do
      where ["daterange(service_start_date, service_end_date, '[]') && daterange(:min, :max, '[]')", { min: date_range.min, max: date_range.max }]
    end

    scope :engaging, -> do
      paid.where(
        procedure_code: 'T2024',
        procedure_modifier_1: 'U4',
        claim_status: 'P',
      )
    end

    scope :paid, -> do
      where(claim_status: 'P')
    end

    scope :matching_icd10cm, ->(pg_regexp_str) do
      # Tip: pg_trgm gist or gin index can make ~ operators fast
      # this will otherwise be slow!
      where <<~SQL.squish, pattern: pg_regexp_str
        COALESCE(icd_version. '10') AND (
          dx_1 ~ :pattern
          OR dx_2 ~ :pattern
          OR dx_3 ~ :pattern
          OR dx_4 ~ :pattern
          OR dx_5 ~ :pattern
          OR dx_6 ~ :pattern
          OR dx_7 ~ :pattern
          OR dx_8 ~ :pattern
          OR dx_9 ~ :pattern
          OR dx_10 ~ :pattern
          OR dx_11 ~ :pattern
          OR dx_12 ~ :pattern
          OR dx_13 ~ :pattern
          OR dx_14 ~ :pattern
          OR dx_15 ~ :pattern
          OR dx_16 ~ :pattern
          OR dx_17 ~ :pattern
          OR dx_18 ~ :pattern
          OR dx_19 ~ :pattern
          OR dx_20 ~ :pattern
        )
      SQL
    end

    scope :matching_icd10pcs, ->(pg_regexp_str) do
      # Tip: pg_trgm gist or gin index can make ~ operators fast
      # this will otherwise be slow!
      where <<~SQL.squish, pattern: pg_regexp_str
        COALESCE(icd_version. '10') = '10' AND (
          surgical_procedure_code_1 ~ :pattern
          OR surgical_procedure_code_2 ~ :pattern
          OR surgical_procedure_code_3 ~ :pattern
          OR surgical_procedure_code_4 ~ :pattern
          OR surgical_procedure_code_5 ~ :pattern
        )
      SQL
    end

    def matches_icd10cm?(regexp, dx1_only = false)
      return false unless (icd_version || '10') == '10'

      dx1_only ? regexp.match?(dx_1) : dx_codes.any? { |code| regexp.match?(code) }
    end

    def matches_icd9cm?(regexp, dx1_only = false)
      return false unless icd_version == 9

      dx1_only ? regexp.match?(dx_1) : dx_codes.any? { |code| regexp.match?(code) }
    end

    def matches_icd10pcs?(regexp)
      ((icd_version || '10') == '10') && surgical_procedure_codes.any? { |code| regexp.match?(code) }
    end

    def matches_icd9pcs?(regexp)
      icd_version == '9' && surgical_procedure_codes.any? { |code| regexp.match?(code) }
    end

    def followup_period(n_days)
      return unless discharge_date

      discharge_date .. n_days.days.after(discharge_date)
    end

    # Calculates and updates the cumulative enrolled and engaged days as of each claims service_start_date.
    #
    # These can go down if there are large gaps in enrollment. Temporary gaps just stop counting days as enrolled.
    #
    # We loop over distinct members_id and update each members claims atomically. This could be done
    # in parallel if needed.
    def self.maintain_engaged_days!
      members = 0
      updates = 0
      log_timing 'maintain_engaged_days!' do
        enrollment_gap_limit = 365.days # a gap longer than this will reset our counters
        last_claim_date = MedicalClaim.maximum(:service_start_date) || Date.current
        member_ids = distinct.pluck(:member_id)
        member_ids.each_with_index do |member_id, idx|
          logger.info { "MedicalClaim.maintain_engaged_days!: Processing member #{idx + 1}/#{member_ids.length}." }
          enrollments = MemberEnrollmentRoster.where(member_id: member_id).select(
            :member_id, :span_start_date, :span_end_date
          ).sort_by(&:span_start_date)

          logger.debug { "MedicalClaim.maintain_engaged_days!: Found #{enrollments.length} enrollment spans" }

          # enrolled_day is the number of days of enrollment to date.
          #
          # Create a map of dates to number of enrolled days to date.
          # Enrollments might overlap (they shouldn't but do) so we have
          # sorted by span_start_date above so the enrollment that gives
          # them the most credited days is used.
          # We stop counting during gaps and start over at zero enrolled days
          # if the gap gets too long.
          enrolled_dates = {}
          enrollments.each_with_index do |e, e_idx|
            range_start = e.span_start_date
            range_end = if e == enrollments.last
              last_claim_date
            else
              enrollments[e_idx + 1].span_start_date
            end
            (range_start .. range_end).each do |date|
              previous_day = (date - 1.day)
              previous_days_count = (enrolled_dates[previous_day] || 0)
              enrolled_dates[date] ||= if date < e.span_end_date
                previous_days_count + 1
              elsif (date - e.span_end_date) > enrollment_gap_limit
                0
              else
                previous_days_count
              end
            end
          end

          # Use that as lookup iterate over all claims for the
          # member from oldest to newest and update the
          # enrolled_days as of the service data. Once
          # we find a valid claim indicating successful engagement
          # we can also set the cumulative engaged_days
          tuples = []
          conn = connection
          engagement_date = nil

          where(member_id: member_id).select(
            :id,
            :service_start_date,
            :claim_status,
            :procedure_code,
            :procedure_modifier_1,
          ).order(service_start_date: :asc).each do |claim|
            enrolled_days = enrolled_dates[claim.service_start_date] || 0

            # Locate a valid QA for Care Plan completion
            engagement_date ||= claim.service_start_date if claim.engaged?

            # engaged_days is the sum of enrolled_days after that point
            engaged_days = if engagement_date
              raise 'claim data out of order' if claim.service_start_date < engagement_date

              previous_day = (engagement_date - 1.day)
              pre_engaged_enrolled_days = enrolled_dates[previous_day] || 0

              # clamp to 0.. if a user becomes engaged on the first day
              # of a enrollment gap (which should be impossible). In that
              # case pre_engaged_enrolled_days would be 365 and
              # enrolled_days would be 0
              (enrolled_days - pre_engaged_enrolled_days).clamp(0, enrolled_days)
            else
              0
            end
            tuples << "(#{conn.quote claim.id},#{conn.quote enrolled_days},#{conn.quote engaged_days})"
          end
          logger.debug { "MedicalClaim.maintain_engaged_days!: Updating #{tuples.size} claim records" }
          updates += tuples.size
          if tuples.any?
            sql = <<~SQL
              UPDATE #{quoted_table_name}
              SET enrolled_days=t.enrolled_days, engaged_days=t.engaged_days
              FROM (VALUES #{tuples.join(',')}) AS t (id, enrolled_days, engaged_days)
              WHERE #{quoted_table_name}.id = t.id
            SQL
            connection.execute(sql)
          end
          members += 1
        end
        updates
      end
      { members: members, updates: updates }
    end

    def stay_date_range
      return nil unless admit_date

      admit_date .. discharge_date
    end

    def engaged?
      completed_treatment_plan?
    end

    def dead_upon_arrival?
      dx_1 == 'R99'
    end

    def discharged_due_to_death?
      patient_status == '20' # UB-04 FL 17 Patient Discharge Status
    end

    # Qualifying Activity: BH CP Treatment Plan Complete
    def completed_treatment_plan?
      procedure_code == 'T2024' && procedure_modifier_1 == 'U4' && claim_status == 'P'
    end

    def modifiers
      [
        procedure_modifier_1,
        procedure_modifier_2,
        procedure_modifier_3,
        procedure_modifier_4,
      ].select(&:present?)
    end
    memoize :modifiers

    def dx_codes
      [
        dx_1, dx_2, dx_3, dx_4, dx_5, dx_6, dx_7, dx_8, dx_9, dx_10,
        dx_11, dx_12, dx_13, dx_14, dx_15, dx_16, dx_17, dx_18, dx_19, dx_20
      ].select(&:present?)
    end
    memoize :dx_codes

    # FIXME? Faster to avoid the casts which we don't happen to need?
    # def dx_codes2
    #   values = []
    #   [
    #     :dx_1, :dx_2, :dx_3, :dx_4, :dx_5, :dx_6, :dx_7, :dx_8, :dx_9,
    #     :dx_10, :dx_11, :dx_12, :dx_13, :dx_14, :dx_15, :dx_16, :dx_17, :dx_18, :dx_19, :dx_20
    #   ].each do |name|
    #     v = read_attribute_before_type_cast(name)
    #     values << v if v.present?
    #   end

    #   values
    # end
    # memoize :dx_codes2

    def surgical_procedure_codes
      [
        surgical_procedure_code_1,
        surgical_procedure_code_2,
        surgical_procedure_code_3,
        surgical_procedure_code_4,
        surgical_procedure_code_5,
      ].select(&:present?)
    end
    memoize :surgical_procedure_codes

    def procedure_with_modifiers
      # sort is here since this is used as a key to match against other data
      ([procedure_code] + modifiers.sort).join('>').to_s
    end
    memoize :procedure_with_modifiers

    include ClaimsReporting::CsvHelpers
    def self.conflict_target
      ['member_id', 'claim_number', 'line_number']
    end

    def self.csv_constraints
      'service_start_date <= service_end_date'
    end

    def self.schema_def
      <<~CSV.freeze
        ID,Field name,Description,Length,Data type,PRIVACY: Encounter pricing
        1,member_id,Member's Medicaid identification number ,50,string,-
        2,claim_number,Claim number,30,string,-
        3,line_number,Claim detail line number,10,string,-
        4,cp_pidsl,CP entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        5,cp_name,CP name,255,string,-
        6,aco_pidsl,ACO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        7,aco_name,ACO name,255,string,-
        8,pcc_pidsl,PCC ID. PIDSL is a combination of provider ID and service location,50,string,-
        9,pcc_name,PCC name,255,string,-
        10,pcc_npi,PCC national provider identifier (NPI),50,string,-
        11,pcc_taxid,PCC tax identification number (TIN),50,string,-
        12,mco_pidsl,MCO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        13,mco_name,MCO name,50,string,-
        14,source,"Payor of the claim: MCO or MMIS (MH). Note that some claims will be paid by MMIS (MH) even if a member is enrolled in an MCO or Model A ACO (e.g., wrap services). ",50,string,-
        15,claim_type,Claim type,255,string,-
        16,member_dob,Member date of birth,30,date (YYYY-MM-DD),-
        17,patient_status,Indicates the status of the member as of the ending service date of the period covered.,255,string,-
        18,service_start_date,Service start date,30,date (YYYY-MM-DD),-
        19,service_end_date,Service end date,30,date (YYYY-MM-DD),-
        20,admit_date,Admit date,30,date (YYYY-MM-DD),-
        21,discharge_date,Discharge date,30,date (YYYY-MM-DD),-
        22,type_of_bill,"The Type of Bill (TOB) is a three digit entry. The first digit is the type of facility, the second digit is the bill classification, and the third digit is frequency.",255,string,-
        23,admit_source,Code identifying the source of admission for inpatient  claims,255,string,-
        24,admit_type,Code which indicates the priority of the admission of a member for inpatient services ,255,string,-
        25,frequency_code,Third character of TYPE_OF_BILL. This field specifies the bill frequency.,255,string,-
        26,paid_date,Paid date,30,date (YYYY-MM-DD),-
        27,billed_amount,Amount requested by provider for services rendered. ,30,"decimal(19,4)",Redacted
        28,allowed_amount,Amount for claim allowed by payor ,30,"decimal(19,4)",Redacted
        29,paid_amount,Amount sent to a provider for payment for services rendered to a member,30,"decimal(19,4)",Redacted
        30,admit_diagnosis,Admitting diagnosis on the claim,50,string,-
        31,dx_1,First-listed Diagnosis. ,50,string,-
        32,dx_2,Diagnosis 2,50,string,-
        33,dx_3,Diagnosis 3,50,string,-
        34,dx_4,Diagnosis 4,50,string,-
        35,dx_5,Diagnosis 5,50,string,-
        36,dx_6,Diagnosis 6,50,string,-
        37,dx_7,Diagnosis 7,50,string,-
        38,dx_8,Diagnosis 8,50,string,-
        39,dx_9,Diagnosis 9,50,string,-
        40,dx_10,Diagnosis 10,50,string,-
        41,dx_11,Diagnosis 11,50,string,-
        42,dx_12,Diagnosis 12,50,string,-
        43,dx_13,Diagnosis 13,50,string,-
        44,dx_14,Diagnosis 14,50,string,-
        45,dx_15,Diagnosis 15,50,string,-
        46,dx_16,Diagnosis 16,50,string,-
        47,dx_17,Diagnosis 17,50,string,-
        48,dx_18,Diagnosis 18,50,string,-
        49,dx_19,Diagnosis 19,50,string,-
        50,dx_20,Diagnosis 20,50,string,-
        51,dx_21,Diagnosis 21,50,string,-
        52,dx_22,Diagnosis 22,50,string,-
        53,dx_23,Diagnosis 23,50,string,-
        54,dx_24,Diagnosis 24,50,string,-
        55,dx_25,Diagnosis 25,50,string,-
        56,e_dx_1,External injury diagnosis 1,50,string,-
        57,e_dx_2,External injury diagnosis 2,50,string,-
        58,e_dx_3,External injury diagnosis 3,50,string,-
        59,e_dx_4,External injury diagnosis 4,50,string,-
        60,e_dx_5,External injury diagnosis 5,50,string,-
        61,e_dx_6,External injury diagnosis 6,50,string,-
        62,e_dx_7,External injury diagnosis 7,50,string,-
        63,e_dx_8,External injury diagnosis 8,50,string,-
        64,e_dx_9,External injury diagnosis 9,50,string,-
        65,e_dx_10,External injury diagnosis 10,50,string,-
        66,e_dx_11,External injury diagnosis 11,50,string,-
        67,e_dx_12,External injury diagnosis 12,50,string,-
        68,icd_version,ICD version type,50,string,-
        69,surgical_procedure_code_1,Surgical procedure code 1,50,string,-
        70,surgical_procedure_code_2,Surgical procedure code 2,50,string,-
        71,surgical_procedure_code_3,Surgical procedure code 3,50,string,-
        72,surgical_procedure_code_4,Surgical procedure code 4,50,string,-
        73,surgical_procedure_code_5,Surgical procedure code 5,50,string,-
        74,surgical_procedure_code_6,Surgical procedure code 6,50,string,-
        75,revenue_code,Revenue code,50,string,-
        76,place_of_service_code,Place of service code,50,string,-
        77,procedure_code,Procedure code,50,string,-
        78,procedure_modifier_1,Procedure modifier 1,50,string,-
        79,procedure_modifier_2,Procedure modifier 2,50,string,-
        80,procedure_modifier_3,Procedure modifier 3,50,string,-
        81,procedure_modifier_4,Procedure modifier 4,50,string,-
        82,drg_code,Code identifying a DRG grouping.,50,string,-
        83,drg_version_code,Description of the DRG grouper.,50,string,-
        84,severity_of_illness,Severity of Illness (SOI) subclass at discharge. ,50,string,-
        85,service_provider_npi,Service provider national provider identifier,50,string,-
        86,id_provider_servicing,Service provider ID,50,string,-
        87,servicing_taxid,Service provider tax identification number (TIN),50,string,-
        88,servicing_provider_name,Service provider name,512,string,-
        89,servicing_provider_type,Type that a servicing provider is licensed for. ,255,string,-
        90,servicing_provider_taxonomy,Service provider taxonomy,255,string,-
        91,servicing_address,Service provider address line 1,512,string,-
        92,servicing_city,Service provider city,255,string,-
        93,servicing_state,Service provider state,255,string,-
        94,servicing_zip,Service provider zip,50,string,-
        95,billing_npi,Billing provider national provider identifier,50,string,-
        96,id_provider_billing,Billing provider ID,50,string,-
        97,billing_taxid,Billing provider  tax identification number TIN,50,string,-
        98,billing_provider_name,Billing provider name,512,string,-
        99,billing_provider_type,Type that a Billing provider is licensed for. ,50,string,-
        100,billing_provider_taxonomy,Billing provider taxonomy,50,string,-
        101,billing_address,Billing provider address line 1,512,string,-
        102,billing_city,Billing provider city,255,string,-
        103,billing_state,Billing provider state,255,string,-
        104,billing_zip,Billing provider zip,50,string,-
        105,claim_status,"Claim status (P - paid, D - denied)",255,string,-
        106,disbursement_code,Disbursement code: represents which state agency is responsible for the claim. 0 is MassHealth paid.,255,string,-
        107,enrolled_flag,Y/N flag depending on if member is current with your entity,50,string,-
        108,referral_circle_ind,Flag (Y /N) used to indicate whether a claim was paid or denied by a service provider who is part of the referral circle,50,string,-
        109,mbhp_flag,Indicator for MBHP claims,50,string,-
        110,present_on_admission_1,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        111,present_on_admission_2,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        112,present_on_admission_3,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        113,present_on_admission_4,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        114,present_on_admission_5,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        115,present_on_admission_6,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        116,present_on_admission_7,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        117,present_on_admission_8,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        118,present_on_admission_9,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        119,present_on_admission_10,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        120,present_on_admission_11,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        121,present_on_admission_12,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        122,present_on_admission_13,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        123,present_on_admission_14,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        124,present_on_admission_15,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        125,present_on_admission_16,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        126,present_on_admission_17,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        127,present_on_admission_18,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        128,present_on_admission_19,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        129,present_on_admission_20,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        130,present_on_admission_21,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        131,present_on_admission_22,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        132,present_on_admission_23,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        133,present_on_admission_24,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        134,present_on_admission_25,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        135,e_dx_present_on_admission_1,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        136,e_dx_present_on_admission_2,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        137,e_dx_present_on_admission_3,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        138,e_dx_present_on_admission_4,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        139,e_dx_present_on_admission_5,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        140,e_dx_present_on_admission_6,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        141,e_dx_present_on_admission_7,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        142,e_dx_present_on_admission_8,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        143,e_dx_present_on_admission_9,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        144,e_dx_present_on_admission_10,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        145,e_dx_present_on_admission_11,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        146,e_dx_present_on_admission_12,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
        147,quantity,Quantity billed,30,"decimal(12,4)",-
        148,price_method,Indicates the pricing method used for payment of the claim,50,string,-
        149,cde_cos_rollup,High-level COS grouping to the categories used in ACO rate setting and reporting.,50,string,-
        150,cde_cos_category,Mid-level categorization of COS. Initial rollup of subcategory COS codes.,50,string,-
        151,cde_cos_subcategory,Most granular categorization of COS. Contains the most detailed description of the service performed on the claim.,50,string,-
        152,ind_mco_aco_cvd_svc,"Y/N flag indicating ACO/MCO covered vs ACO/MCO non-covered services (e.g., wrap services)",50,string,-
        153,cde_ndc,The National Drug Code used to identify the drug. Applies to paid Outpatient and Professional claims.,48,string,-
      CSV
    end
  end
end
