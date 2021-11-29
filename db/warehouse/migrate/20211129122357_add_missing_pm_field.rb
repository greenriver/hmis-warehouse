class AddMissingPmField < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_clients, :comparison_days_homeless_es_sh_th_ph, :integer
  end
end
