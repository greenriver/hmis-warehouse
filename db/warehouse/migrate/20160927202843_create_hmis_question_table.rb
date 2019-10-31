class CreateHmisQuestionTable < ActiveRecord::Migration[4.2]
  def change
    table_name = :hmis_questions
    create_table table_name do |t|
      t.string :text
    end
  end
end
