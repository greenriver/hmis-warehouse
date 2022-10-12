class AddDebuggingColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_spm_clients, :personal_id, :string
    add_column :hud_report_spm_clients, :data_lab_public_id, :string
  end
end
