class UpdateFinancialTables < ActiveRecord::Migration[6.1]
  def change
    # These tables are empty at this time, so the following is safe
    StrongMigrations.disable_check(:rename_column)
    rename_column :financial_clients, :do_you_have_a_voucher, :does_the_client_have_a_tenant_based_housing_voucher
    rename_column :financial_clients, :housed_date, :date_of_referral_to_wit
    rename_column :financial_clients, :was_the_client_screened_for_homelessness, :deleted_was_the_client_screened_for_homelessness
    add_column :financial_clients, :was_the_client_screened_for_homelessness, :string
    rename_column :financial_clients, :are_rental_arrears_owed, :delete_are_rental_arrears_owed
    add_column :financial_clients, :are_rental_arrears_owed, :string
    ensure
      StrongMigrations.enable_check(:rename_column)
  end
end
