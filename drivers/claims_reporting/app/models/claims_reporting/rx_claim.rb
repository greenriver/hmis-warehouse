###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class RxClaim < HealthBase
    phi_patient :member_id
    belongs_to :patient, foreign_key: :member_id, class_name: 'Health::Patient', primary_key: :medicaid_id, optional: true

    belongs_to :member_roster, primary_key: :member_id, foreign_key: :member_id, optional: true
    include ClaimsReporting::CsvHelpers

    scope :service_in, ->(date_range) do
      where(
        arel_table[:service_start_date].lt(date_range.max).
        and(
          arel_table[:service_end_date].gteq(date_range.min).
          or(arel_table[:service_end_date].eq(nil)),
        ),
      )
    end

    def self.conflict_target
      ['member_id', 'claim_number', 'line_number']
    end

    def self.schema_def
      <<~CSV.freeze
        ID,Field name,Description,Length,Data type,PRIVACY: Encounter pricing,,
        1,member_id,Member's Medicaid identification number ,50,string,-,,
        2,claim_number,Claim number,30,string,-,,
        3,line_number,Claim detail line number,10,string,-,,
        4,cp_pidsl,CP entity ID. PIDSL is a combination of provider ID and service location,50,string,-,,
        5,cp_name,CP name,255,string,-,,
        6,aco_pidsl,ACO entity ID. PIDSL is a combination of provider ID and service location,50,string,-,,
        7,aco_name,ACO name,255,string,-,,
        8,pcc_pidsl,PCC ID. PIDSL is a combination of provider ID and service location,50,string,-,,
        9,pcc_name,PCC name,255,string,-,,
        10,pcc_npi,PCC national provider identifier (NPI),50,string,-,,
        11,pcc_taxid,PCC tax identification number (TIN),50,string,-,,
        12,mco_pidsl,MCO entity ID. PIDSL is a combination of provider ID and service location,50,string,-,,
        13,mco_name,MCO name,50,string,-,,
        14,source,"Payor of the claim: MCO or MMIS. Note that some claims will be paid by MMIS (MH) even if a member is enrolled in an MCO or Model A ACO (e.g., wrap services). ",50,string,-,,
        15,claim_type,Claim type,255,string,-,,
        16,member_dob,Member date of birth,30,date (YYYY-MM-DD),-,,
        17,refill_quantity,"This is the refill number for the prescribed drug. This is not the available number of refills. The first time the prescription is filled, this attribute will be 0. The second time is filled - the first refill - this attribute will be 1. The third time is 2.",20,string,-,,
        18,service_start_date,Service start date,30,date (YYYY-MM-DD),-,,
        19,service_end_date,Service end date,30,date (YYYY-MM-DD),-,,
        20,paid_date,Paid date,30,date (YYYY-MM-DD),-,,
        21,days_supply,Number of days provided for a prescribed drug. ,20,int,-,,
        22,billed_amount,Amount requested by provider for services rendered. ,30,"decimal(19,4)",Redacted,,
        23,allowed_amount,Amount for claim allowed by payor ,30,"decimal(19,4)",Redacted,,
        24,paid_amount,Amount sent to a provider for payment for services rendered to a member,30,"decimal(19,4)",Redacted,,
        25,prescriber_npi,Prescriber national provider identifier (NPI),50,string,-,,
        26,id_prescriber_servicing,Prescriber ID,50,string,-,,
        27,prescriber_taxid,Prescriber tax identification number (TIN),50,string,-,,
        28,prescriber_name,Prescriber name,255,string,-,,
        29,prescriber_type,Code qualifying the prescribing provider ID from NCPDP Version 5.1. ,50,string,-,,
        30,prescriber_taxonomy,Prescriber taxonomy,50,string,-,,
        31,prescriber_address,Prescriber address line 1,512,string,-,,
        32,prescriber_city,Prescriber city,255,string,-,,
        33,prescriber_state,Prescriber state,255,string,-,,
        34,prescriber_zip,Prescriber zip,50,string,-,,
        35,billing_npi,Billing provider national provider identifier (NPI),50,string,-,,
        36,id_provider_billing,Billing provider ID,50,string,-,,
        37,billing_taxid,Billing provider tax identification number (TIN),50,string,-,,
        38,billing_provider_name,Billing provider name,255,string,-,,
        39,billing_provider_type,Billing provider type,50,string,-,,
        40,billing_provider_taxonomy,Billing provider taxonomy,50,string,-,,
        41,billing_address,Billing provider address line 1,512,string,-,,
        42,billing_city,Billing provider city,255,string,-,,
        43,billing_state,Billing provider state,255,string,-,,
        44,billing_zip,Billing provider zip,50,string,-,,
        45,ndc_code,The National Drug Code used to identify the drug.,50,string,-,,
        46,dosage_form_code,Dosage form code,50,string,-,,
        47,therapeutic_class,Drug therapy class,50,string,-,,
        48,daw_ind,Dispense as written indicator,50,string,-,,
        49,gcn,Generic code number,50,string,-,,
        50,claim_status,"Claim status (P - paid, D - denied)",50,string,-,,
        51,disbursement_code,Disbursement code: represents which state agency is responsible for the claim. 0 is MassHealth paid.,50,string,-,,
        52,enrolled_flag,Y/N flag depending on if member is current with your entity,50,string,-,,
        53,drug_name,Drug name,512,string,-,,
        54,brand_vs_generic_indicator,Brand vs generic indicator; will be blank for MCO claims,50,int,-,,
        55,price_method,Indicates the pricing method used for payment of the claim,50,string,-,,
        56,quantity,Quantity billed,30,"decimal(12,4)",-,,
        57,route_of_administration,Route of administration,255,string,-,,
        58,cde_cos_rollup,,50,string,-
        59,cde_cos_category,,50,string,-
        60,cde_cos_subcategory,,50,string,-
        61,ind_mco_aco_cvd_svc,,50,string,-
      CSV
    end
  end
end
