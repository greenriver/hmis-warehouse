class AddYouthFollowUps < ActiveRecord::Migration
  def change
    create_table :youth_follow_ups do |t|
      t.references :client
      t.references :user
      t.date :contacted_on
      t.string :housing_status
      t.string :zip_code

      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
