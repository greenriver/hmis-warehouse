class AddAmountToDirectFinancialAssistance < ActiveRecord::Migration[5.2]
  def change
    add_column :direct_financial_assistances, :amount, :decimal
  end
end
