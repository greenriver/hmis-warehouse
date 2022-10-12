class CreateFormDefinitions < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_form_definitions do |t|
      t.integer :version, null: false
      t.string :identifier, null: false
      t.string :role, null: false, comment: 'Usually one of INTAKE, UPDATE, ANNUAL, EXIT, POST_EXIT, CE, CUSTOM'
      t.string :status, null: false, comment: 'Usually one of active, draft, retired'
      t.jsonb :definition, comment: 'Based on FHIR format'
      t.timestamps
    end
    create_table :hmis_form_instances do |t|
      t.references :entity, polymorphic: true
      t.string :definition_identifier, null: false
      t.timestamps
    end
    create_table :hmis_assessment_details do |t|
      t.references :assessment
      t.references :definition
      t.integer :data_collection_stage, null: false, comment: 'One of the HMIS 5.03.1 or 99 for local use'
      t.string :role, null: false, comment: 'Usually one of INTAKE, UPDATE, ANNUAL, EXIT, POST_EXIT, CE, CUSTOM'
      t.string :status, comment: 'Usually one of submitted, draft'
      t.timestamps
    end
  end
end
