class AddCustomServiceTypes < ActiveRecord::Migration[6.1]
  def up
    create_table :CustomServiceCategories do |t|
      t.string :name, null: false, comment: 'Name of service category (eg Financial Assistance)'
      t.string :UserID, limit: 32, null: false
      t.integer :data_source_id
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    # Table storing available service types, includes Custom service types and HUD service types
    create_table :CustomServiceTypes do |t|
      t.string :name, null: false, comment: 'Name of this service (eg HAP Rental Assistance)'
      t.references :custom_service_category, comment: 'Category that this service belongs to'
      t.integer :hud_record_type, comment: 'Only applicable if this is a HUD service'
      t.integer :hud_type_provided, comment: 'Only applicable if this is a HUD service'
      t.string :UserID, limit: 32, null: false
      t.integer :data_source_id
      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    # Table storing non-HUD Services rendered
    create_table :CustomServices do |t|
      t.string :CustomServiceID, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.string :UserID, limit: 32, null: false
      t.date :DateProvided, null: false
      t.integer :data_source_id
      t.references :custom_service_type, comment: 'Reference to the type of service rendered'
      t.string :service_name, comment: 'Name of service rendered (for export)'

      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end
  end

  def down
    drop_table :CustomServiceCategories
    drop_table :CustomServiceTypes
    drop_table :CustomServices
  end
end
