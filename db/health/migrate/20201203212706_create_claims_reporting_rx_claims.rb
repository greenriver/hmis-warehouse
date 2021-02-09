class CreateClaimsReportingRxClaims < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_rx_claims do |t|
      t.column 'member_id', 'string', limit: 50
      t.column 'claim_number', 'string', limit: 30
      t.column 'line_number', 'string', limit: 10
      t.column 'cp_pidsl', 'string', limit: 50
      t.column 'cp_name', 'string', limit: 255
      t.column 'aco_pidsl', 'string', limit: 50
      t.column 'aco_name', 'string', limit: 255
      t.column 'pcc_pidsl', 'string', limit: 50
      t.column 'pcc_name', 'string', limit: 255
      t.column 'pcc_npi', 'string', limit: 50
      t.column 'pcc_taxid', 'string', limit: 50
      t.column 'mco_pidsl', 'string', limit: 50
      t.column 'mco_name', 'string', limit: 50
      t.column 'source', 'string', limit: 50
      t.column 'claim_type', 'string', limit: 255
      t.column 'member_dob', 'date', limit: nil
      t.column 'refill_quantity', 'string', limit: 20
      t.column 'service_start_date', 'date', limit: nil
      t.column 'service_end_date', 'date', limit: nil
      t.column 'paid_date', 'date', limit: nil
      t.column 'days_supply', 'int', limit: nil
      t.column 'billed_amount', 'decimal(19,4)', limit: nil
      t.column 'allowed_amount', 'decimal(19,4)', limit: nil
      t.column 'paid_amount', 'decimal(19,4)', limit: nil
      t.column 'prescriber_npi', 'string', limit: 50
      t.column 'id_prescriber_servicing', 'string', limit: 50
      t.column 'prescriber_taxid', 'string', limit: 50
      t.column 'prescriber_name', 'string', limit: 255
      t.column 'prescriber_type', 'string', limit: 50
      t.column 'prescriber_taxonomy', 'string', limit: 50
      t.column 'prescriber_address', 'string', limit: 512
      t.column 'prescriber_city', 'string', limit: 255
      t.column 'prescriber_state', 'string', limit: 255
      t.column 'prescriber_zip', 'string', limit: 50
      t.column 'billing_npi', 'string', limit: 50
      t.column 'id_provider_billing', 'string', limit: 50
      t.column 'billing_taxid', 'string', limit: 50
      t.column 'billing_provider_name', 'string', limit: 255
      t.column 'billing_provider_type', 'string', limit: 50
      t.column 'billing_provider_taxonomy', 'string', limit: 50
      t.column 'billing_address', 'string', limit: 512
      t.column 'billing_city', 'string', limit: 255
      t.column 'billing_state', 'string', limit: 255
      t.column 'billing_zip', 'string', limit: 50
      t.column 'ndc_code', 'string', limit: 50
      t.column 'dosage_form_code', 'string', limit: 50
      t.column 'therapeutic_class', 'string', limit: 50
      t.column 'daw_ind', 'string', limit: 50
      t.column 'gcn', 'string', limit: 50
      t.column 'claim_status', 'string', limit: 50
      t.column 'disbursement_code', 'string', limit: 50
      t.column 'enrolled_flag', 'string', limit: 50
      t.column 'drug_name', 'string', limit: 512
      t.column 'brand_vs_generic_indicator', 'int', limit: nil
      t.column 'price_method', 'string', limit: 50
      t.column 'quantity', 'decimal(12,4)', limit: nil
      t.column 'route_of_administration', 'string', limit: 255
    end
  end
end
