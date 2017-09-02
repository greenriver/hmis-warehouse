class AddClaimsMetrics < ActiveRecord::Migration
  def change
    create_table :claims_claim_volume_location_month do |t|
      t.string :medicaid_id, index: true, null: false
      t.integer :year
      t.integer :month
      t.integer :ip
      t.integer :emerg
      t.integer :respite
      t.integer :op
      t.integer :rx
      t.integer :other
      t.integer :total
    end
    create_table :claims_amount_paid_location_month do |t|
      t.string :medicaid_id, index: true, null: false
      t.integer :year
      t.integer :month
      t.integer :ip
      t.integer :emerg
      t.integer :respite
      t.integer :op
      t.integer :rx
      t.integer :other
      t.integer :total
    end
    create_table :claims_top_providers do |t|
      t.string :medicaid_id, index: true, null: false
      t.integer :rank
      t.string :provider_name
      t.float :indiv_pct
      t.float :sdh_pct
    end
    create_table :claims_top_conditions do |t|
      t.string :medicaid_id, index: true, null: false
      t.integer :rank
      t.string :description
      t.float :indiv_pct
      t.float :sdh_pct
    end
    create_table :claims_top_ip_conditions do |t|
      t.string :medicaid_id, index: true, null: false
      t.integer :rank
      t.string :description
      t.float :indiv_pct
      t.float :sdh_pct
    end
    create_table :claims_ed_nyu_severity do |t|
      t.string :medicaid_id, index: true, null: false
      t.integer :rank
      t.string :category
      t.float :indiv_pct
      t.float :sdh_pct
    end
    create_table :claims_roster do |t|
      t.string :medicaid_id, index: true, null: false
      t.string :last_name
      t.string :first_name
      t.string :gender
      t.date :dob
      t.string :race
      t.string :primary_language
      t.boolean :disability_flag
      t.float :norm_risk_score
      t.integer :mbr_months
      t.integer :total_ty
      t.integer :ed_visits
      t.integer :acute_ip_admits
      t.integer :average_days_to_readmit
      t.string :pcp
      t.string :epic_team
    end
  end
end
