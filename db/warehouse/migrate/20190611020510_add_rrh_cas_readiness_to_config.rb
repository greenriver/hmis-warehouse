class AddRrhCasReadinessToConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :rrh_cas_readiness, :boolean, default: :false
  end
end
