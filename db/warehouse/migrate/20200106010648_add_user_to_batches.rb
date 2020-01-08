class AddUserToBatches < ActiveRecord::Migration[5.2]
  def change
    add_column :ad_hoc_batches, :user_id, :integer
  end
end
