class AddTrainingCompletedToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :training_completed, :boolean, default: false
  end
end
