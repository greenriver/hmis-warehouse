class AddPathwaysAnswersToHmisForms < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_forms, :pathways_updated_at, :datetime

    add_column :hmis_forms, :assessment_completed_on, :date
    add_column :hmis_forms, :assessment_score, :integer
    add_column :hmis_forms, :rrh_desired, :boolean, default: false, null: false
    add_column :hmis_forms, :youth_rrh_desired, :boolean, default: false, null: false
    add_column :hmis_forms, :rrh_assessment_contact_info, :string
    add_column :hmis_forms, :adult_rrh_desired, :boolean, default: false, null: false
    add_column :hmis_forms, :rrh_th_desired, :boolean, default: false, null: false
    add_column :hmis_forms, :income_maximization_assistance_requested, :boolean, default: false, null: false
    add_column :hmis_forms, :income_total_annual, :integer
    add_column :hmis_forms, :pending_subsidized_housing_placement, :boolean, default: false, null: false
    add_column :hmis_forms, :domestic_violence, :boolean, default: false, null: false
    add_column :hmis_forms, :interested_in_set_asides, :boolean, default: false, null: false
    add_column :hmis_forms, :required_number_of_bedrooms, :integer
    add_column :hmis_forms, :required_minimum_occupancy, :integer
    add_column :hmis_forms, :requires_wheelchair_accessibility, :boolean, default: false, null: false
    add_column :hmis_forms, :requires_elevator_access, :boolean, default: false, null: false
    add_column :hmis_forms, :youth_rrh_aggregate, :string
    add_column :hmis_forms, :dv_rrh_aggregate, :string
    add_column :hmis_forms, :veteran_rrh_desired, :boolean, default: false, null: false
    add_column :hmis_forms, :sro_ok, :boolean, default: false, null: false
    add_column :hmis_forms, :other_accessibility, :boolean, default: false, null: false
    add_column :hmis_forms, :disabled_housing, :boolean, default: false, null: false
    add_column :hmis_forms, :evicted, :boolean, default: false, null: false
    add_column :hmis_forms, :neighborhood_interests, :jsonb, default: []
  end
end
