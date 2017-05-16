class CreateVisits < ActiveRecord::Migration
  def change
    create_table :visits do |t|
      t.date :visit_date
      t.string :department
      t.string :type
      t.string :provider
      t.timestamps null: false
      t.references :patient, index: true
    end
  end
end
