class AddConfigForCasSync < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :cas_calculator, :string, null: false, default: 'GrdaWarehouse::CasProjectClientCalculator::Default'
  end
end
