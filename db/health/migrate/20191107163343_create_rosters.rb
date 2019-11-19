class CreateRosters < ActiveRecord::Migration[4.2]
  def change
    create_table :rosters do |t|
      t.belongs_to :roster_file

      t.string :member_id
      t.string :nam_first
      t.string :nam_last
      t.string :cp_pidsl
      t.string :cp_name
      t.string :aco_pidsl
      t.string :aco_name
      t.string :mco_pidsl
      t.string :mco_name
      t.string :sex
      t.date :date_of_birth
      t.string :mailing_address_1
      t.string :mailing_address_2
      t.string :mailing_city
      t.string :mailing_state
      t.string :mailing_zip
      t.string :residential_address_1
      t.string :residential_address_2
      t.string :residential_city
      t.string :residential_state
      t.string :residential_zip
      t.string :race
      t.string :phone_number
      t.string :primary_language_s
      t.string :primary_language_w
      t.string :sdh_nss7_score
      t.string :sdh_homelessness
      t.string :sdh_addresses_flag
      t.string :sdh_other_disabled
      t.string :sdh_spmi
      t.string :raw_risk_score
      t.string :normalized_risk_score
      t.string :raw_dxcg_risk_score
      t.date :last_office_visit
      t.date :last_ed_visit
      t.date :last_ip_visit
      t.string :enrolled_flag
      t.string :enrollment_status
      t.date :cp_claim_dt
      t.string :qualifying_hcpcs
      t.string :qualifying_hcpcs_nm
      t.string :qualifying_dsc
      t.string :email
      t.string :head_of_household
    end
  end
end
