class AddExternalReferrals < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_unit_types do |t|
      t.timestamps
      t.string :description
      t.integer :bed_type # HUD bed type
      t.integer :unit_size
    end

    create_table :hmis_external_referral_requests do |t|
      t.timestamps
      t.string :identifier, null: false, index: { unique: true, name: 'uidx_hmis_external_referral_requests_identifier' }
      # the project advertising the vacancy
      t.references :project, null: false, foreign_key: { to_table: 'Project' }
      t.references :unit_type, null: false, foreign_key: { to_table: :hmis_unit_types }
      t.date :requested_on, null: false
      t.date :needed_by, null: false
      t.references :requested_by # User, fk not possible
      t.string :requestor_name, null: false
      t.string :requestor_phone, null: false
      t.string :requestor_email, null: false
      t.datetime :voided_at
      t.references :voided_by # User, fk not possible
    end

    create_table :hmis_external_referrals do |t|
      t.timestamps
      t.string :identifier, null: false, index: { unique: true, name: 'uidx_hmis_external_referrals_identifier' }
      t.date :referral_date, null: false
      t.string :service_coordinator, null: false
      t.string :raw_request
    end

    create_table :hmis_external_referral_clients do |t|
      t.timestamps
      t.references :referral, null: false, foreign_key: { to_table: :hmis_external_referrals }, index: { name: 'idx_hmis_external_referral_clients_on_referral_id' }
      t.references :hud_client, null: false, index: false, foreign_key: { to_table: 'Client' }
      t.index [:hud_client_id, :referral_id], unique: true, name: 'uidx_hmis_external_referral_clients_1'
    end

    create_table :hmis_external_referral_postings do |t|
      t.timestamps
      t.string :identifier, null: false, index: { unique: true, name: 'uidx_hmis_external_referral_posting_identifier' }
      t.integer :status, null: false
      t.references :referral, null: false, foreign_key: { to_table: :hmis_external_referrals }, index: false
      t.references :referral_request, null: false, foreign_key: { to_table: :hmis_external_referral_requests },
                                      index: { name: 'idx_hmis_external_referral_postings_on_request_id' }
      t.index [:referral_id, :referral_request_id], unique: true, name: 'uidx_hmis_external_referral_postings_1'
    end
  end
end
