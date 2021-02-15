class AddColsToCrMedicalClaims < ActiveRecord::Migration[5.2]
  def change
    change_table :claims_reporting_medical_claims do |t|
      t.column 'cde_cos_rollup', 'string', limit: 50
      t.column 'cde_cos_category', 'string', limit: 50
      t.column 'cde_cos_subcategory', 'string', limit: 50
      t.column 'ind_mco_aco_cvd_svc', 'string', limit: 50
    end

    change_table :claims_reporting_rx_claims do |t|
      t.column 'cde_cos_rollup', 'string', limit: 50
      t.column 'cde_cos_category', 'string', limit: 50
      t.column 'cde_cos_subcategory', 'string', limit: 50
      t.column 'ind_mco_aco_cvd_svc', 'string', limit: 50
    end

    change_table :claims_reporting_member_rosters do |t|
      t.column 'sdh_smi', 'string', limit: 50
    end
  end
end
