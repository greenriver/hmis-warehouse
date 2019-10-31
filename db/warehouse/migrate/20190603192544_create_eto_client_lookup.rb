class CreateEtoClientLookup < ActiveRecord::Migration[4.2]
  def change
    create_table :eto_client_lookups do |t|
      t.references :data_source, index: true, null: false
      t.references :client, index: true, null: false
      t.string :enterprise_guid, null: false
      t.integer :participant_site_identifier, null: false
      t.integer :site_id, null: false
      t.integer :subject_id, null: false
      t.datetime :last_updated
    end

    create_table :eto_touch_point_lookups do |t|
      t.references :data_source, index: true, null: false
      t.references :client, index: true, null: false
      t.integer :subject_id, null: false
      t.integer :assessment_id, null: false
      t.integer :response_id, null: false
      t.datetime :last_updated
    end
  end
end
