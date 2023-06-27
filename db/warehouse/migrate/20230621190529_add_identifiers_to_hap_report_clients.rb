class AddIdentifiersToHapReportClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hap_report_clients, :personal_id, :string
    add_column :hap_report_clients, :mci_id, :string
  end
end
