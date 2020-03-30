class AddLastTrainingCompletedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_training_completed, :date
  end
end
