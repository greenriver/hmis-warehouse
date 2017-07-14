class AddIndexesToDates < ActiveRecord::Migration
  def change
    add_index :Services, :DateProvided
  end
end
