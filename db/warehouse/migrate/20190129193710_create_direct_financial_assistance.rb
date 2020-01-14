class CreateDirectFinancialAssistance < ActiveRecord::Migration[4.2]
  def change
    create_table :direct_financial_assistances do |t|
      t.references :client
      t.references :user
      t.date :provided_on
      t.string :type_provided

      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
