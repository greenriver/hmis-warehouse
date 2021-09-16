class AddGenderFields < ActiveRecord::Migration[5.2]
  def change
    [
      :female,
      :male,
      :nosinglegender,
      :transgender,
      :questioning,
      :gendernone,
    ].each do |column|
      add_column :warehouse_houseds, column, :integer
      add_column :warehouse_returns, column, :integer
    end
  end
end
