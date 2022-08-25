class CreateHmisDataQualityToolReports < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_dqt_clients do |t|
      t.references :client, index: true, null: false
      t.references :report, index: true, null: false
      t.string :first_name
      t.string :last_name
      t.string :personal_id
      t.integer :data_source_id
      t.integer :male
      t.integer :female
      t.integer :no_single_gender
      t.integer :transgender
      t.integer :questioning

      t.timestamps
    end
    create_table :hmis_dqt_enrollments do |t|
      t.references :enrollment, index: true, null: false
      t.references :client, index: true, null: false
      t.references :report, index: true, null: false

      t.string :personal_id
      t.string :project_name

      t.string :hmis_enrollment_id
      t.string :exit_id
      t.integer :data_source_id
      t.date :entry_date
      t.date :move_in_date
      t.date :exit_date
      t.integer :disabling_condition
      t.integer :living_situation
      t.integer :relationship_to_hoh
      t.string :coc_code
      t.integer :destination
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.integer :project_tracking_method

      t.timestamps
    end

    create_table :hmis_dqt_services do |t|
      t.references :service, index: true, null: false
      t.references :enrollment, index: true, null: false
      t.references :client, index: true, null: false
      t.references :report, index: true, null: false

      t.string :project_name
      t.string :hmis_service_id
      t.integer :data_source_id
      t.date :date_provided
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.integer :project_tracking_method
      t.timestamps
    end

    create_table :hmis_dqt_current_living_situations do |t|
      t.references :current_living_situation, index: false, null: false
      t.references :enrollment, index: true, null: false
      t.references :client, index: true, null: false
      t.references :report, index: true, null: false

      t.string :project_name
      t.string :hmis_current_living_situation_id
      t.integer :data_source_id
      t.integer :current_living_situation
      t.date :information_date
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.integer :project_tracking_method
      t.timestamps
    end

    add_index(:hmis_dqt_current_living_situations, :current_living_situation, name: :hmis_dqt_cls_cls_id)

    create_table :hmis_dqt_events do |t|
      t.references :event, index: true, null: false
      t.references :enrollment, index: true, null: false
      t.references :client, index: true, null: false
      t.references :report, index: true, null: false

      t.string :project_name
      t.string :hmis_event_id
      t.integer :data_source_id
      t.integer :event
      t.date :event_date
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.timestamps
    end

    create_table :hmis_dqt_assessments do |t|
      t.references :assessment, index: true, null: false
      t.references :enrollment, index: true, null: false
      t.references :client, index: true, null: false
      t.references :report, index: true, null: false

      t.string :project_name
      t.string :hmis_assessment_id
      t.integer :data_source_id
      t.integer :assessment_type
      t.integer :assessment_level
      t.integer :prioritization_status
      t.date :assessment_date
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.timestamps
    end

    create_table :hmis_dqt_projects do |t|
      t.references :project, index: true, null: false
      t.references :report, index: true, null: false

      t.string :project_name
      t.string :hmis_project_id
      t.string :hmis_organization_id
      t.integer :data_source_id
      t.integer :project_type
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.timestamps
    end

    create_table :hmis_dqt_inventories do |t|
      t.references :inventory, index: true, null: false
      t.references :project, index: true, null: false
      t.references :report, index: true, null: false

      t.string :project_name
      t.string :hmis_inventory_id
      t.integer :data_source_id
      t.integer :project_type
      t.date :project_operating_start_date
      t.date :project_operating_end_date
      t.integer :unit_inventory
      t.integer :bed_inventory
      t.integer :ch_vet_bed_inventory
      t.integer :youth_vet_bed_inventory
      t.integer :vet_bed_inventory
      t.integer :ch_youth_bed_inventory
      t.integer :youth_bed_inventory
      t.integer :ch_bed_inventory
      t.integer :other_bed_inventory
      t.integer :inventory_start_date
      t.integer :inventory_end_date
      t.timestamps
    end
  end
end
