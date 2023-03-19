class AddSourceClientPersonalIDs < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_spm_clients, :source_client_personal_ids, :string
  end
end
