class ConvertConsentTagsToFull < ActiveRecord::Migration[4.2]
  def up
    GrdaWarehouse::AvailableFileTag.where(name: ['HAN Release', 'Full HAN Release', 'Consent Form']).update_all(full_release: true)
  end
end
