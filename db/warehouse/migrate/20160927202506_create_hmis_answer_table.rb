class CreateHmisAnswerTable < ActiveRecord::Migration
  def change
    table_nameo = :hmis_answers
    create_table table_nameo do |t|
      t.integer :assessment_id, null: false
      t.integer :question_id, null: false
      t.string :text
    end
    add_index table_nameo, [:assessment_id, :question_id], unique: true
  end
end
