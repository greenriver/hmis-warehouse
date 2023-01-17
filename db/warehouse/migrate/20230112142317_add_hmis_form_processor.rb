class AddHmisFormProcessor < ActiveRecord::Migration[6.1]
  def change
    add_reference :hmis_assessment_details, :processor

    create_table :hmis_assessment_processors do |t|
      # HMIS keys are strings
      t.string :enrollment_coc_id
      t.string :health_and_dv_id
      t.string :income_benefit_id
      t.string :physical_disability_id
      t.string :developmental_disability_id
      t.string :chronic_health_condition_id
      t.string :hiv_aids_id
      t.string :mental_health_disorder_id
      t.string :substance_use_disorder_id
    end
  end
end
