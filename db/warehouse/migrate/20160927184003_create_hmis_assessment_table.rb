class CreateHmisAssessmentTable < ActiveRecord::Migration
  def change
    table_name = GrdaWarehouse::HMIS::Assessment.table_name
    create_table table_name do |t|
      t.string :type, null: false
      t.integer :client_id, null: false
      t.integer :staff_id
      t.datetime :response_created_at

      t.timestamps
    end
  end
end
