class RemoveCustomForm < ActiveRecord::Migration[6.1]
  def change
    Hmis::Hud::CustomAssessment.delete_all
    Hmis::Form::FormProcessor.delete_all

    drop_table :CustomForms
    add_column :hmis_form_processors, :custom_assessment_id, :integer, null: false
    add_column :hmis_form_processors, :definition_id, :integer, null: true
    add_column :hmis_form_processors, :wip_values, :jsonb, null: true
    add_column :hmis_form_processors, :youth_education_status_id, :integer, null: true
    add_column :hmis_form_processors, :employment_education_id, :integer, null: true
    add_column :hmis_form_processors, :current_living_situation_id, :integer, null: true
  end
end
