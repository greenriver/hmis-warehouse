###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Lookup tables and tools for HL7 standardized data
module Hl7
  def self.table_name_prefix
    'hl7_'
  end

  PROCEDURE_CODE_SYSTEMS = ['HCPCS', 'CPT', 'CPT-CAT-II'].freeze
  REVENUE_CODE_SYSTEMS = ['UBREV'].freeze
  APC_EXTRA_PROC_CODES = ['99386', '99387', '99396', '99397', 'T1015'].freeze

  def self.ed_visit?(claim)
    in_set?('ED', claim)
  end

  def self.inpatient_stay?(claim)
    in_set?('Inpatient Stay', claim)
  end

  def self.acute_inpatient_hospital?(_claim)
    # TODO: We need get a lookup of "Acute Inpatient Hospital IDs"
    # from somewhere
    false
  end

  def self.acute_inpatient_stay?(claim)
    inpatient_stay?(claim) && !in_set?('Nonacute Inpatient Stay', claim)
  end

  def self.mental_health_hospitalization?(claim)
    (
      in_set?('Mental Illness', claim, dx1_only: true) || in_set?('Intentional Self-Harm', claim, dx1_only: true)
    ) && acute_inpatient_stay?(claim)
  end

  def self.schizophrenia_or_bipolar_disorder?(claims)
    # ... Schizophrenia Value Set; Bipolar Disorder Value Set; Other Bipolar Disorder Value Set
    claims_with_dx = claims.select do |c|
      in_set?('Schizophrenia', c) || in_set?('Bipolar Disorder', c) || in_set?('Other Bipolar Disorder', c)
    end
    return false if claims_with_dx.none?

    # > At least one acute inpatient encounter, with any diagnosis of schizophrenia, schizoaffective disorder or bipolar disorder.
    # - BH Stand Alone Acute Inpatient Value Set with...
    # - Visit Setting Unspecified Value Set with Acute Inpatient POS Value Set...
    return true if claims_with_dx.any? { |c| in_set?('BH Stand Alone Acute Inpatient', c) || (in_set?('Visit Setting Unspecified', c) && in_set?('Acute Inpatient POS', c)) }

    # > At least two of the following, on different dates of service, with or without a telehealth modifier (Telehealth Modifier Value Set)
    visits = claims_with_dx.select do |c|
      in_set?('Visit Setting Unspecified', c) && (
        in_set?('Acute Inpatient POS', c) ||
          in_set?('Community Mental Health Center POS', c) ||
          in_set?('ED POS', c) ||
          in_set?('Nonacute Inpatient POS', c) ||
          in_set?('Partial Hospitalization POS', c) ||
          in_set?('Telehealth POS', c)
      ) ||
        in_set?('BH Outpatient', c) ||
        in_set?('BH Stand Alone Nonacute Inpatient', c) ||
        in_set?('ED', c) ||
        in_set?('Electroconvulsive Therapy', c) ||
        in_set?('Observation', c) ||
        in_set?('Partial Hospitalization/Intensive Outpatient', c)
    end

    # > where both encounters have any diagnosis of schizophrenia or schizoaffective disorder (Schizophrenia Value Set)
    return true if visits.select { |c| in_set?('Schizophrenia', c) }.uniq(&:service_start_date).size >= 2

    # > or both encounters have any diagnosis of bipolar disorder (Bipolar Disorder Value Set; Other Bipolar Disorder Value Set).
    return true if visits.select { |c| in_set?('Bipolar Disorder', c) || in_set?('Other Bipolar Disorder', c) }.uniq(&:service_start_date).size >= 2

    return false
  end

  def self.pcp_practitioner?(_claim)
    # TODO
    true
  end

  def self.ob_gyn_practitioner?(_claim)
    # TODO
    true
  end

  def self.hospice?(claim)
    (
      claim.procedure_code.in?(value_set_codes('Hospice', PROCEDURE_CODE_SYSTEMS)) ||
        claim.revenue_code.in?(value_set_codes('Hospice', REVENUE_CODE_SYSTEMS))
    )
  end

  def self.aod_dx?(claim)
    in_set?('AOD Abuse and Dependence', claim) || in_set?('AOD Medication', claim)
  end

  def self.aod_rx?(rx_claim)
    (
      in_set?('Medication Treatment for Alcohol Abuse or Dependence Medications List', rx_claim) ||
        in_set?('Medication Treatment for Opioid Abuse or Dependence Medications List', rx_claim)
    )
  end

  def self.aod_abuse_or_dependence?(claim)
    # New episode of AOD abuse or dependence
    # TODO: this may need to be evaluated on all the claims in the same 'stay'
    # This is used to find a IESD

    c = claim
    aod_abuse = (
      in_set?('Alcohol Abuse and Dependence', c) ||
        in_set?('Opioid Abuse and Dependence', c) ||
        in_set?('Other Drug Abuse and Dependence', c)
    ) # && value_set_codes('Telehealth Modifier Value', PROCEDURE_CODE_SYSTEMS)

    return false unless aod_abuse # we can bail no other condition can match

    raise 'FIXME: We have not had AOD data to date so the logic below has no real world testing' if aod_abuse

    # direct translation of the English spec
    (
      in_set?('IET Stand Alone Visits', c) && aod_abuse
    ) || (
      in_set?('IET Visits Group 1', c) && in_set?('IET POS Group 1', c) && aod_abuse
    ) || (
      in_set?('IET Visits Group 2', c) && in_set?('IET POS Group 2', c) && aod_abuse
    ) || (
      in_set?('Detoxification', c) && aod_abuse
    ) || (
      in_set?('ED', c) && aod_abuse
    ) || (
      in_set?('Observation', c) && aod_abuse
    ) || (
      inpatient_stay?(c) && aod_abuse
    ) || (
      in_set?('Telephone Visits', c) && aod_abuse
    ) || (
      in_set?('Online Assessments', c) && aod_abuse
    )
  end

  def self.annual_primary_care_visit?(claim)
    # ... comprehensive physical examination (Well-Care Value
    # Set, or any of the following procedure codes: 99386, 99387, 99396,
    # 99397 [CPT]; T1015 [HCPCS]) with a PCP or an OB/GYN practitioner
    # (Provider Type Definition Workbook). The practitioner does not have to
    # be the practitioner assigned to the member. The comprehensive
    # well-care visit can happen any time during the measurement year; it
    # does not need to occur during a CP enrollment period.
    (
      in_set?('Well-Care', claim) ||
        (claim.procedure_code.in?(APC_EXTRA_PROC_CODES) && (pcp_practitioner?(claim) || ob_gyn_practitioner?(claim)))
    )
  end

  def self.cp_followup?(claim)
    # > Qualifying Activity: Follow up after Discharge submitted by the BH CP to the Medicaid Management
    # > Information System (MMIS) and identified via code G9007 with a U5 modifier. In addition to the
    # > U5 modifier...
    # TODO: Not sure if we need to check for U1/U2 or not, nor how to check for "comprised of a face-to-face visit"
    # > ...the following modifiers may be included: U1 or U2. This follow-up must be
    # > comprised of a face-to-face visit with the enrollee.)
    claim.procedure_code == 'G9007' && claim.modifiers.include?('U5')
  end

  def self.in_set?(vs_name, claim, dx1_only: false)
    codes_by_system = value_set_lookups.fetch(vs_name) do
      raise "Value Set '#{vs_name}' is unknown"
      # {}
    end
    raise "Value Set '#{vs_name}' has no codes defined" if codes_by_system.empty?

    # TODO: Can we use LOINC (labs) or CVX (vaccine) codes?
    # TODO: What about "Modifier"?

    # MY 2020 HEDIS for QRS Version—NCQA Page - 2021 QRS Measure TechSpecs_20200925_508.pdf  Sec 37 Code Modifiers
    # > Modifiers are two extensions that, when added to CPT or HCPCS codes,
    # > provide additional information about a service or procedure. Exclude
    # > any CPT Category II code in conjunction with a 1P, 2P, 3P or 8P
    # > modifier code (CPT CAT II Modifier Value Set) from HEDIS for QRS
    # > reporting.  These modifiers indicate the service did not occur. In
    # > the HEDIS for QRS Value Set Directory, CPT Category II codes are
    # > identified in the Code System column as “CPT-CAT-II.” Unless
    # > otherwise specified, if a CPT or HCPCS code specified in HEDIS for
    # > QRS appears in the organization’s database with any modifier other
    # > than those specified above, the code may be counted in the HEDIS for
    # > QRS measure.

    # Check first because its very likely to match
    procedure_codes = Set.new
    PROCEDURE_CODE_SYSTEMS.each do |code_system|
      procedure_codes |= codes_by_system[code_system] if codes_by_system[code_system]
    end
    return trace_set_match!(vs_name, claim, PROCEDURE_CODE_SYSTEMS) if procedure_codes.include?(claim.procedure_code)

    # Check easy ones next
    if (revenue_codes = codes_by_system['UBREV']).present?
      return trace_set_match!(vs_name, claim, :UBREV) if revenue_codes.include?(claim.revenue_code)
    end

    # https://www.findacode.com/articles/type-of-bill-table-34325.html
    if (bill_types = codes_by_system['UBTOB']).present?
      return trace_set_match!(vs_name, claim, :UBTOB) if bill_types.include?(claim.type_of_bill)
    end

    if (place_of_service_codes = codes_by_system['POS'])
      return trace_set_match!(vs_name, claim, :POS) if place_of_service_codes.include?(claim.place_of_service_code)
    end

    # Slower set intersection ones, current ICD version
    if (code_pattern = codes_by_system['ICD10CM'])
      return trace_set_match!(vs_name, claim, :ICD10CM) if claim.matches_icd10cm?(code_pattern, dx1_only)
    end
    if (code_pattern = codes_by_system['ICD10PCS'])
      return trace_set_match!(vs_name, claim, :ICD10PCS) if claim.matches_icd10pcs? code_pattern
    end

    # Slow and rare
    if (code_pattern = codes_by_system['ICD9CM'])
      return trace_set_match!(vs_name, claim, :ICD9CM) if claim.matches_icd9cm?(code_pattern, dx1_only)
    end

    if (code_pattern = codes_by_system['ICD9PCS']) # rubocop:disable Style/GuardClause
      return trace_set_match!(vs_name, claim, :ICD9PCS) if claim.matches_icd9pcs? code_pattern
    end
  end

  def self.rx_in_set?(vs_name, claim)
    codes_by_system = value_set_lookups.fetch(vs_name)

    # TODO: RxNorm, CVX might also show up lookup code but we dont have any claims data with that info, nor a crosswalk handy
    # TODO: raise/warn on an unrecognised code_system_name?

    if (ndc_codes = codes_by_system['NDC']).present? # rubocop:disable Style/GuardClause
      return trace_set_match!(vs_name, claim, :NDC) if ndc_codes.include?(claim.ndc_code)
    end
  end

  def self.trace_set_match!(vs_name, claim, code_type) # rubocop:disable Lint/UnusedMethodArgument
    # puts "in_set? #{vs_name} matched #{code_type} for Claim#id=#{claim.id}"
    true
  end

  # efficiently loads, caches, returns
  # a 2-level lookup table: value_set_name -> code_system_name -> Set<codes> | RegExp
  def self.value_set_lookups
    @value_set_lookups ||= begin
      sets = VALUE_SETS.keys.map do |vs_name|
        [vs_name, {}]
      end.to_h

      oid_to_name = VALUE_SETS.invert
      rows = Hl7::ValueSetCode.where(
        value_set_oid: VALUE_SETS.values,
      ).pluck(:value_set_oid, :code_system, :code)

      rows.each do |value_set_oid, code_system, code|
        vs_name = oid_to_name.fetch(value_set_oid)
        sets[vs_name][code_system] ||= []
        sets[vs_name][code_system] << code
      end

      lookup_table = {}

      sets.each do |vs_name, code_system_data|
        lookup_table[vs_name] = {}
        code_system_data.each do |code_system, codes|
          # We need to process these lookup tables to work well wth the claims reporting data
          if code_system.in? ['ICD10CM', 'ICD10PCS', 'ICD9CM', 'ICD10PCS']
            # we don't generally have decimals in data and should match on prefixes
            codes = codes.map { |code| code.gsub('.', '') }
            lookup_table[vs_name][code_system] = Regexp.new "^(#{codes.join('|')})"
          elsif code_system.in? ['UBTOB', 'UBREV']
            # our claims data doesn't have leading zeros
            codes = codes.flat_map { |code| code.gsub(/^0/, '') }
            lookup_table[vs_name][code_system] = Set.new codes
          else
            lookup_table[vs_name][code_system] = Set.new codes
          end
        end
      end

      lookup_table.transform_values(&:freeze)
      lookup_table.freeze
    end
  end

  def self.value_set_codes(name, code_systems)
    @value_set_codes ||= value_set_lookups.fetch(name.to_s).values_at(*Array(code_systems)).flatten.compact
  end

  # Map the names used in the various CMS Quality Rating System specs
  # to the OIDs. Names will not be unique in Hl7::ValueSetCode as we load
  # other sources
  # Note: We were missing names used in BH CP 10 from the standard sources
  # so a custom list from our TA partner was loaded under the non-standard
  # 'x.' placeholder OIDs
  # - Schizophrenia
  # - Bipolar Disorder
  # - Other Bipolar Disorder
  # - BH Stand Alone Acute Inpatient
  # - BH Stand Alone Nonacute Inpatient
  # - Nonacute Inpatient POS
  # - Long-Acting Injections - see note near "Long Acting Injections" in MEDICATION_LISTS
  MEDICATION_LISTS = {
    'SSD Antipsychotic Medications' => '2.16.840.1.113883.3.464.1004.2173',
    'Diabetes Medications' => '2.16.840.1.113883.3.464.1004.2050',
    'Opioid Use Disorder Treatment Medications' => '2.16.840.1.113883.3.464.1004.2142',
    'Alcohol Use Disorder Treatment Medications' => '2.16.840.1.113883.3.464.1004.2026',
    # Note, the MH spec says there is a "Long-Active Injections" claims Value Set
    # which I was not able to find. These med lists seem like a good proxy for now
    'Long Acting Injections 14 Days Supply Medications' => '2.16.840.1.113883.3.464.1004.2100',
    'Long Acting Injections 30 Days Supply Medications' => '2.16.840.1.113883.3.464.1004.2190',
    'Long Acting Injections 28 Days Supply Medications' => '2.16.840.1.113883.3.464.1004.2101',
  }.freeze

  VALUE_SETS = MEDICATION_LISTS.merge(
    {
      'Acute Condition' => '2.16.840.1.113883.3.464.1004.1324',
      'Acute Inpatient' => '2.16.840.1.113883.3.464.1004.1810',
      'Acute Inpatient POS' => '2.16.840.1.113883.3.464.1004.1027',
      'Alcohol Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1424',
      'Ambulatory Surgical Center POS' => '2.16.840.1.113883.3.464.1004.1480',
      'AOD Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1013',
      'AOD Medication Treatment' => '2.16.840.1.113883.3.464.1004.2017',
      'BH Outpatient' => '2.16.840.1.113883.3.464.1004.1481',
      'Bone Marrow Transplant' => '2.16.840.1.113883.3.464.1004.1325',
      'Chemotherapy' => '2.16.840.1.113883.3.464.1004.1326',
      'Community Mental Health Center POS' => '2.16.840.1.113883.3.464.1004.1484',
      'Detoxification' => '2.16.840.1.113883.3.464.1004.1076',
      'Diabetes' => '2.16.840.1.113883.3.464.1004.1077',
      'ED POS' => '2.16.840.1.113883.3.464.1004.1087',
      'ED' => '2.16.840.1.113883.3.464.1004.1086',
      'Electroconvulsive Therapy' => '2.16.840.1.113883.3.464.1004.1294',
      'HbA1c Tests' => '2.16.840.1.113883.3.464.1004.1116',
      'Hospice' => '2.16.840.1.113883.3.464.1004.1418',
      'IET POS Group 1' => '2.16.840.1.113883.3.464.1004.1129',
      'IET POS Group 2' => '2.16.840.1.113883.3.464.1004.1130',
      'IET Stand Alone Visits' => '2.16.840.1.113883.3.464.1004.1131',
      'IET Visits Group 1' => '2.16.840.1.113883.3.464.1004.1132',
      'IET Visits Group 2' => '2.16.840.1.113883.3.464.1004.1133',
      'Inpatient Stay' => '2.16.840.1.113883.3.464.1004.1395',
      'Intentional Self-Harm' => '2.16.840.1.113883.3.464.1004.1468',
      'Introduction of Autologous Pancreatic Cells' => '2.16.840.1.113883.3.464.1004.1459',
      'Kidney Transplant' => '2.16.840.1.113883.3.464.1004.1141',
      'Mental Health Diagnosis' => '2.16.840.1.113883.3.464.1004.1178',
      'Mental Illness' => '2.16.840.1.113883.3.464.1004.1179',
      'Nonacute Inpatient Stay' => '2.16.840.1.113883.3.464.1004.1398',
      'Nonacute Inpatient' => '2.16.840.1.113883.3.464.1004.1189',
      'Observation' => '2.16.840.1.113883.3.464.1004.1191',
      'Observation Stay' => '2.16.840.1.113883.3.464.1004.1461',
      'Online Assessments' => '2.16.840.1.113883.3.464.1004.1446',
      'Opioid Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1425',
      'Organ Transplant Other Than Kidney' => '2.16.840.1.113883.3.464.1004.1195',
      'Other Drug Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1426',
      'Outpatient POS' => '2.16.840.1.113883.3.464.1004.1443',
      'Outpatient' => '2.16.840.1.113883.3.464.1004.1202',
      'Partial Hospitalization POS' => '2.16.840.1.113883.3.464.1004.1491',
      'Partial Hospitalization/Intensive Outpatient' => '2.16.840.1.113883.3.464.1004.1492',
      'Perinatal Conditions' => '2.16.840.1.113883.3.464.1004.1209',
      'Potentially Planned Procedures' => '2.16.840.1.113883.3.464.1004.1327',
      'Pregnancy' => '2.16.840.1.113883.3.464.1004.1219',
      'Rehabilitation' => '2.16.840.1.113883.3.464.1004.1328',
      'Surgery Procedure' => '2.16.840.1.113883.3.464.1004.2223',
      'Telehealth Modifier' => '2.16.840.1.113883.3.464.1004.1445',
      'Telehealth POS' => '2.16.840.1.113883.3.464.1004.1460',
      'Telephone Visits' => '2.16.840.1.113883.3.464.1004.1246',
      'Transitional Care Management Services' => '2.16.840.1.113883.3.464.1004.1462',
      'Visit Setting Unspecified' => '2.16.840.1.113883.3.464.1004.1493',
      'Well-Care' => '2.16.840.1.113883.3.464.1004.1262',
      'Schizophrenia' => 'x.Schizophrenia',
      'Bipolar Disorder' => 'x.Bipolar Disorder',
      'Other Bipolar Disorder' => 'x.Other Bipolar Disorder',
      'BH Stand Alone Acute Inpatient' => 'x.BH Stand Alone Acute Inpatient',
      'BH Stand Alone Nonacute Inpatient' => 'x.BH Stand Alone Nonacute Inpatient',
      'Nonacute Inpatient POS' => 'x.Nonacute Inpatient POS',
    },
  ).freeze
end
HL7 = Hl7
