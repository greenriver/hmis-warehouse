class CreateSimpleReportInstances < ActiveRecord::Migration[5.2]
  def change
    create_table :simple_report_instances do |t|
      t.string :type
      t.json :options
      t.references :user

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
