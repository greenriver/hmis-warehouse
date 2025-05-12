class EnhanceImporterLog < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_csv_importer_logs, :phase_metrics, :jsonb
  end
end
