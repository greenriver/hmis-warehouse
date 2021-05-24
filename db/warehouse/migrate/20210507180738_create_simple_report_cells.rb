class CreateSimpleReportCells < ActiveRecord::Migration[5.2]
  def change
    create_table :simple_report_cells do |t|
      t.references :report_instance
      t.string :name
      t.boolean :universe, default: false
      t.integer :summary

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
