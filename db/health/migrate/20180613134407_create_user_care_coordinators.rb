class CreateUserCareCoordinators < ActiveRecord::Migration[4.2]
  def change
    create_table :user_care_coordinators do |t|
      t.references :user
      t.references :care_coordinator
      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
