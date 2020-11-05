class AddHistoryGeneratedOnToEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :Enrollment, :history_generated_on, :date
  end
end
