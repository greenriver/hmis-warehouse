class AddFaAmountRanges < ActiveRecord::Migration[6.1]
  def change
    # new in 2024 spec
    add_column :Services, :FAStartDate, :date, null: true
    add_column :Services, :FAEndDate, :date, null: true

    # add to CustomServices for custom financial assistance
    add_column :CustomServices, :FAAmount, :float, null: true
    add_column :CustomServices, :FAStartDate, :date, null: true
    add_column :CustomServices, :FAEndDate, :date, null: true
  end
end
