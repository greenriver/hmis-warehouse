class AddCoursesToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :training_courses, :jsonb
  end
end