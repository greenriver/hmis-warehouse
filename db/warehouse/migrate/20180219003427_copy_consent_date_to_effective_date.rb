class CopyConsentDateToEffectiveDate < ActiveRecord::Migration[4.2]
  def up
    GrdaWarehouse::ClientFile.where.not(consent_form_signed_on: nil).each do |file|
      file.update_columns(effective_date: file.consent_form_signed_on)
    end
  end
end
