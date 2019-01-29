class CreateDirectFinancialAssistance < ActiveRecord::Migration
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
