class ConsentLimitWindowConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :consent_exposes_all_data_sources, :boolean, default: true
  end
end
