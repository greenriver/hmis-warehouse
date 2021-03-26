class CreateStatusDates < ActiveRecord::Migration[5.2]
  def change
    create_table :status_dates do |t|
      t.references :patient, index: true, null: false
      t.date :date, null: false, index: true
      t.boolean :engaged, null: false
      t.boolean :enrolled, null: false
    end
  end
end
