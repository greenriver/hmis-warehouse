class CreateAssessmentAnswerLookup < ActiveRecord::Migration[5.2]
  def change
    create_table :assessment_answer_lookups do |t|
      t.string :assessment_question
      t.string :response_code, index: true
      t.string :response_text
      t.timestamps null: false
    end
  end
end
