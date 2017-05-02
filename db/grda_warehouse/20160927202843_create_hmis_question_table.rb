class CreateHmisQuestionTable < ActiveRecord::Migration
  def change
    table_name = GrdaWarehouse::HMIS::Question.table_name
    create_table table_name do |t|
      t.string :text
    end
  end
end
