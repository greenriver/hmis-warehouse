class AddObeyConsentToDataSources < ActiveRecord::Migration[6.1]
  def change
    add_column :data_sources, :obey_consent, :boolean, default: true
  end
end
