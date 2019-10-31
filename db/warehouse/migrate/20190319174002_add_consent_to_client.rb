class AddConsentToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :consent_expires_on, :date, index: true

    add_column :hmis_forms, :vispdat_score_updated_at, :datetime
    add_column :hmis_forms, :vispdat_total_score, :float
    add_column :hmis_forms, :vispdat_youth_score, :float
    add_column :hmis_forms, :vispdat_family_score, :float
    add_column :hmis_forms, :vispdat_months_homeless, :float
    add_column :hmis_forms, :vispdat_times_homeless, :float
  end
end
