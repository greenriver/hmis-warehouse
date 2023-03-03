class AddCustomAssessments < ActiveRecord::Migration[6.1]
  def change
    create_table :CustomAssessments do |t|
      t.string :CustomAssessmentID, null: false
      t.string :EnrollmentID, null: false
      t.string :PersonalID, null: false
      t.string :UserID, limit: 32, null: false
      t.date :AssessmentDate, null: false
      t.integer :DataCollectionStage, null: false, comment: 'One of the HMIS 5.03.1, or 99 for local use'
      t.integer :data_source_id

      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    create_table :CustomClientAssessments do |t|
      t.string :CustomClientAssessmentID, null: false
      t.string :PersonalID, null: false
      t.string :UserID, limit: 32, null: false
      t.date :InformationDate, null: false
      t.integer :data_source_id

      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    create_table :CustomProjectAssessments do |t|
      t.string :CustomProjectAssessmentID, null: false
      t.string :ProjectID, null: false
      t.string :UserID, limit: 32, null: false
      t.date :InformationDate, null: false
      t.integer :data_source_id

      t.datetime :DateCreated, null: false
      t.datetime :DateUpdated, null: false
      t.datetime :DateDeleted
    end

    GrdaWarehouseBase.connection.table_exists? 'hmis_assessment_processors'
      rename_table :hmis_assessment_processors, :hmis_form_processors
    else
      create_table :hmis_form_processors do |t|
        t.references :enrollment_coc
        t.references :health_and_dv
        t.references :income_benefit
        t.references :physical_disability
        t.references :developmental_disability
        t.references :chronic_health_condition
        t.references :hiv_aids
        t.references :mental_health_disorder
        t.references :substance_use_disorder
        t.references :exit
      end
    end

    create_table :CustomForms do |t|
      t.references :owner, null: false, polymorphic: true
      t.references :definition, null: false
      t.references :form_processor
      t.jsonb :values
      t.jsonb :hud_values

      t.datetime :deleted_at
      t.timestamps
    end

    # Key-Value pairs of custom form responses
    create_table :CustomFormAnswers do |t|
      t.references :custom_form, null: false
      t.references :owner, null: false, polymorphic: true, comment: 'Record that this data element applies to (Client, Project, etc)'
      t.string :link_id, comment: 'Link ID of the item in the definition that this answer corresponds to'
      t.string :key, comment: 'Human-readable key for this data element'
      t.float :value_float
      t.integer :value_integer
      t.boolean :value_boolean
      t.string :value_string
      t.text :value_text
      t.jsonb :value_json

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
