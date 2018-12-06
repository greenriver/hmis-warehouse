class CreateCasClientHistory < ActiveRecord::Migration
  def change
    create_table :cas_non_hmis_client_histories do |t|
      t.integer :cas_client_id, null: false, index: true
      t.date :available_on, null: false
      t.date :unavailable_on
      t.boolean :part_of_a_family, null: false, default: false
      t.integer :age_at_available_on
    end

    add_column :cas_reports, :cas_client_id, :integer, index: true
    add_column :cas_reports, :client_move_in_date, :date

    create_table :cas_availabilities do |t|
      t.integer :client_id, null: false, index: true
      t.datetime :available_at, null: false, index: true
      t.datetime :unavailable_at, index: true
    end
  end
end
