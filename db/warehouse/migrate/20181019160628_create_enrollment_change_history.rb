class CreateEnrollmentChangeHistory < ActiveRecord::Migration
  def change
    create_table :enrollment_change_histories do |t|
      t.references :client, index: true, null: false
      t.date :on, null: false
      t.jsonb :residential
      t.jsonb :other
      t.timestamps
    end
  end
end
