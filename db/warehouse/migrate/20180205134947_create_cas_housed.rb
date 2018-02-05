class CreateCasHoused < ActiveRecord::Migration
  def change
    create_table :cas_houseds do |t|
      t.references :client, index: true, null: false
      t.references :cas_client, null: false
      t.references :match, null: false
      t.date :housed_on, null: false
      t.boolean :inactivated, default: false
    end
  end
end
