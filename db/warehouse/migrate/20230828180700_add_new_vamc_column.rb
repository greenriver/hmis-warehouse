class AddNewVamcColumn < ActiveRecord::Migration[6.1]
  def change
    add_column :Enrollment, :VAMCStation_new, :string, null: true
  end
end
