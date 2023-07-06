class CreateFinancialClients < ActiveRecord::Migration[6.1]
  def change
    create_table :financial_providers do |t|
      t.integer :provider_id, null: false
      t.integer :data_source_id, null: false

      t.string :agency_name, null: false
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :service_provider_area
      t.string :service_provider_area_by_city
      t.string :pha_contracts
      t.string :client_referral_process
      t.string :client_referral_process_other
      t.string :voucher_types_for_client
      t.string :housing_programs
      t.string :housing_program_other

      t.timestamps
      t.datetime :deleted_at

      t.index [:provider_id, :data_source_id], unique: true, name: 'p_id_ds_id_fp_idx'
    end

    create_table :financial_clients do |t|
      t.integer :external_client_id, null: false
      t.integer :client_id, comment: 'Reference to a destination client'
      t.integer :data_source_id, null: false

      t.string :client_first_name
      t.string :client_last_name
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :service_provder_company
      t.integer :head_of_household
      t.integer :was_the_client_screened_for_homelessness
      t.integer :do_you_have_a_voucher
      t.string :if_yes_what_pha_issued_the_voucher
      t.string :if_yes_what_type_of_voucher_was_issued
      t.string :voucher_type_other
      t.string :what_housing_program_is_the_client_in
      t.string :housing_program_other
      t.datetime :date_vouchered_if_applicable
      t.datetime :date_of_referral_to_agency
      t.datetime :lease_start_date
      t.string :city_of_unit
      t.decimal :income
      t.integer :household_members
      t.integer :household_members_under_18
      t.integer :household_members_over_62
      t.datetime :client_birthdate
      t.integer :ada_needs
      t.string :race
      t.string :gender
      t.string :ethnicity
      t.string :cal_optima_client_id
      t.integer :dv_survivor
      t.string :most_recent_living_situation
      t.string :most_recent_living_situation_other
      t.datetime :housed_date
      t.integer :are_rental_arrears_owed
      t.decimal :rent_owed_rental_arrears
      t.integer :total_time_housed
      t.string :hmis_id_if_applicable
      t.integer :housed_after_18_months
      t.integer :housed_after_24_months
      t.timestamps
      t.datetime :deleted_at

      t.index [:external_client_id, :data_source_id], unique: true, name: 'ex_id_ds_id_fc_idx'
    end

    create_table :financial_transactions do |t|
      t.integer :transaction_id, null: false
      t.integer :data_source_id, null: false

      t.string :transaction_status, null: false
      t.datetime :transaction_date, null: false
      t.datetime :paid_date
      t.integer :external_client_id, null: false
      t.integer :provider_id, null: false
      t.timestamps
      t.datetime :deleted_at

      t.index [:transaction_id, :data_source_id], unique: true, name: 'tx_id_ds_id_ft_idx'
    end
  end
end
