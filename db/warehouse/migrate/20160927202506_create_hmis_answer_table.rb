class CreateHmisAnswerTable < ActiveRecord::Migration
  def up 
    create_table :hmis_answers do |t|
      t.integer :assessment_id, null: false
      t.integer :question_id, null: false
      t.string :text
    end
    add_index :hmis_answers, [:assessment_id, :question_id], unique: true
  end

  def down
    drop_table :hmis_answers
  end
end
