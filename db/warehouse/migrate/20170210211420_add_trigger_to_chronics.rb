class AddTriggerToChronics < ActiveRecord::Migration
  def change
    add_column :chronics, :trigger, :string
  end
end
