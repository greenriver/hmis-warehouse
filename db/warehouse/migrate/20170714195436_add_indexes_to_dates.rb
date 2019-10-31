class AddIndexesToDates < ActiveRecord::Migration[4.2]
  def change
    add_index :Services, :DateProvided
  end
end
