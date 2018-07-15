class CreateClaims < ActiveRecord::Migration
  def change
    create_table :claims do |t|
      t.references :user
      t.date :max_date
      t.references :job
      t.integer :max_isa_control_number
      t.integer :max_group_control_number
      t.integer :max_st_number
      t.text :claims_file
      t.datetime :started_at
      t.datetime :completed_at
      t.string :error
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end

    add_reference :qualifying_activities, :claim
  end
end
