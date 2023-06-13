class CreatePctpNeeds < ActiveRecord::Migration[6.1]
  def change
    create_table :pctp_needs do |t|
      t.references :careplan

      t.string :domain
      t.string :need_or_condition
      t.date :start_date
      t.date :end_date
      t.string :status

      t.timestamps
    end
  end
end
