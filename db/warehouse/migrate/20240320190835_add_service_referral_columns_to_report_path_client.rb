class AddServiceReferralColumnsToReportPathClient < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_path_clients, :cmh_service_provided, :boolean, default: false, null: false
    add_column :hud_report_path_clients, :cmh_referral_provided_and_attained, :boolean, default: false, null: false
  end
end
