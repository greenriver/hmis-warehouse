class AddRrhCasReadinessToConfig < ActiveRecord::Migration
  def change
    add_column :configs, :rrh_cas_readiness, :boolean, default: :false
  end
end
