class AddOverallPopulationToPublicConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :public_report_settings, :map_overall_population_method, :string, null: false, default: 'state'
  end
end
