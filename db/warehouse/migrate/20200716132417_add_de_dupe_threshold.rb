class AddDeDupeThreshold < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :auto_de_duplication_accept_threshold, :float
    add_column :configs, :auto_de_duplication_reject_threshold, :float
  end
end
