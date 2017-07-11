class CreateHmisQuestionTable < ActiveRecord::Migration
  def change
    table_name = :hmis_questions
    create_table table_name do |t|
      t.string :text
    end
  end
end
