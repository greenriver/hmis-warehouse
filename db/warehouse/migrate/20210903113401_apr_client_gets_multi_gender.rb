class AprClientGetsMultiGender < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :gender_multi, :jsonb, default: []
  end
end
