class CreateAgencies < ActiveRecord::Migration[4.2]
  def change
    create_table :agencies do |t|
      t.string :name
    end
  end
end
