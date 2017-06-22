class CreateHmisAnswerTable < ActiveRecord::Migration
  def change
    table_name = GrdaWarehouse::HMIS::Answer.table_name
    create_table table_name do |t|
      t.integer :assessment_id, null: false
      t.integer :question_id, null: false
      t.string :text
    end
    add_index table_name, [:assessment_id, :question_id], unique: true
  end
end
