class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.references :patient
      t.references :source, polymorphic: true

      t.string :name
      t.string :category
      t.string :description
      t.string :phone
      t.string :email
      t.date :collected_on

      t.timestamps

      t.index [:patient_id, :source_id, :source_type], unique: true
    end
  end
end
