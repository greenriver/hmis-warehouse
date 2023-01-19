class AddHmisFormProcessor < ActiveRecord::Migration[6.1]
  def change
    add_reference :hmis_assessment_details, :assessment_processor

    create_table :hmis_assessment_processors do |t|
      t.references :enrollment_coc
      t.references :health_and_dv
      t.references :income_benefit
      t.references :physical_disability
      t.references :developmental_disability
      t.references :chronic_health_condition
      t.references :hiv_aids
      t.references :mental_health_disorder
      t.references :substance_use_disorder
    end
  end
end
