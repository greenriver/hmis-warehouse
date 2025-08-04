class AddAgencyNameToAppUsers < ActiveRecord::Migration[7.1]
  def change
    add_column 'analytics.app_users', :agency_name, :string
    add_column :cas_analytics_referral_users, :cas_user_id, :bigint
    add_column :cas_analytics_referral_contacts, :cas_user_id, :bigint
  end
end
