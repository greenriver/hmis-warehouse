class RemoveCustomForm < ActiveRecord::Migration[6.1]
  def up
    Hmis::Hud::CustomAssessment.delete_all
    Hmis::Form::FormProcessor.delete_all

    drop_table :CustomForms
    add_column :hmis_form_processors, :custom_assessment_id, :integer, null: false
    add_column :hmis_form_processors, :definition_id, :integer, null: true
    add_column :hmis_form_processors, :values, :jsonb, null: true
    add_column :hmis_form_processors, :hud_values, :jsonb, null: true
    add_column :hmis_form_processors, :youth_education_status_id, :integer, null: true
    add_column :hmis_form_processors, :employment_education_id, :integer, null: true
    add_column :hmis_form_processors, :current_living_situation_id, :integer, null: true
  end

  def down
    create_table :CustomForms do |t|
      t.references :owner, null: false, polymorphic: true
      t.references :definition, null: false
      t.references :form_processor, null: true
      t.jsonb :values
      t.jsonb :hud_values
      t.timestamps
    end
    remove_column :hmis_form_processors, :custom_assessment_id, :integer, null: false
    remove_column :hmis_form_processors, :definition_id, :integer, null: true
    remove_column :hmis_form_processors, :values, :jsonb, null: true
    remove_column :hmis_form_processors, :hud_values, :jsonb, null: true
    remove_column :hmis_form_processors, :youth_education_status_id, :integer, null: true
    remove_column :hmis_form_processors, :employment_education_id, :integer, null: true
    remove_column :hmis_form_processors, :current_living_situation_id, :integer, null: true
  end
end
