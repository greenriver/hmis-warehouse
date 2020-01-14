class CreateEtoTouchPointResponseTimes < ActiveRecord::Migration[4.2]
  def change
    create_table :eto_touch_point_response_times do |t|
      t.integer :touch_point_unique_identifier, null: false
      t.integer :response_unique_identifier, null: false
      t.datetime :response_last_updated, null: false
      t.integer :subject_unique_identifier, null: false
    end
  end
end
