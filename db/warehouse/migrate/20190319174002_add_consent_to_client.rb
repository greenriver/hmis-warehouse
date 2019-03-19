class AddConsentToClient < ActiveRecord::Migration
  def change
    add_column :Client, :consent_expires_on, :date, index: true
    add_column :hmis_forms, :vispdat_total_score, :float
    add_column :hmis_forms, :vispdat_youth_score, :float
    add_column :hmis_forms, :vispdat_family_score, :float
    add_column :hmis_forms, :vispdat_individual_score, :float
    add_column :hmis_forms, :vispdat_months_homeless, :float
    add_column :hmis_forms, :vispdat_times_homeless, :float
  end
end
