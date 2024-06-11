class AddCsgReportResultModels < ActiveRecord::Migration[6.1]
  def change
    create_table(:csg_engage_program_reports) do |t|
      t.timestamps
      t.belongs_to :program_mapping, to_table: :csg_engage_program_mappings, index: true
      t.belongs_to :report, to_table: :csg_engage_reports, index: true
      t.string :raw_result
      t.jsonb :json_result
      t.jsonb :error_data
      t.jsonb :warning_data
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
    end
  end
end
