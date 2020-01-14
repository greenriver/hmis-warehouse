class AddTriggerToChronics < ActiveRecord::Migration[4.2]
  def change
    add_column :chronics, :trigger, :string
  end
end
