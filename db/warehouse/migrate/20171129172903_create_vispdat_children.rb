class CreateVispdatChildren < ActiveRecord::Migration

  def change
    create_table :children do |t|
      t.string :first_name
      t.string :last_name
      t.date :dob
      t.belongs_to :family, index: true

      t.timestamps null: false
    end
  end

end
