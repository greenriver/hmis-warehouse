class CreateClaimsReportingMemberRosters < ActiveRecord::Migration[5.2]
  def change
    create_table :claims_reporting_member_rosters do |t|
      t.column 'member_id', 'string', limit: 50
      t.column 'nam_first', 'string', limit: 255
      t.column 'nam_last', 'string', limit: 255
      t.column 'cp_pidsl', 'string', limit: 50
      t.column 'cp_name', 'string', limit: 255
      t.column 'aco_pidsl', 'string', limit: 50
      t.column 'aco_name', 'string', limit: 255
      t.column 'mco_pidsl', 'string', limit: 50
      t.column 'mco_name', 'string', limit: 50
      t.column 'sex', 'string', limit: 50
      t.column 'date_of_birth', 'date', limit: nil
      t.column 'mailing_address_1', 'string', limit: 512
      t.column 'mailing_address_2', 'string', limit: 512
      t.column 'mailing_city', 'string', limit: 255
      t.column 'mailing_state', 'string', limit: 255
      t.column 'mailing_zip', 'string', limit: 50
      t.column 'residential_address_1', 'string', limit: 512
      t.column 'residential_address_2', 'string', limit: 512
      t.column 'residential_city', 'string', limit: 255
      t.column 'residential_state', 'string', limit: 255
      t.column 'residential_zip', 'string', limit: 50
      t.column 'race', 'string', limit: 50
      t.column 'phone_number', 'string', limit: 50
      t.column 'primary_language_s', 'string', limit: 255
      t.column 'primary_language_w', 'string', limit: 255
      t.column 'sdh_nss7_score', 'string', limit: 50
      t.column 'sdh_homelessness', 'string', limit: 50
      t.column 'sdh_addresses_flag', 'string', limit: 50
      t.column 'sdh_other_disabled', 'string', limit: 50
      t.column 'sdh_spmi', 'string', limit: 50
      t.column 'raw_risk_score', 'string', limit: 50
      t.column 'normalized_risk_score', 'string', limit: 50
      t.column 'raw_dxcg_risk_score', 'string', limit: 50
      t.column 'last_office_visit', 'date', limit: nil
      t.column 'last_ed_visit', 'date', limit: nil
      t.column 'last_ip_visit', 'date', limit: nil
      t.column 'enrolled_flag', 'string', limit: 50
      t.column 'enrollment_status', 'string', limit: 50
      t.column 'cp_claim_dt', 'date', limit: nil
      t.column 'qualifying_hcpcs', 'string', limit: 50
      t.column 'qualifying_hcpcs_nm', 'string', limit: 255
      t.column 'qualifying_dsc', 'string', limit: 512
      t.column 'email', 'string', limit: 512
      t.column 'head_of_household', 'string', limit: 512
    end
  end
end
