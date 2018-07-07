class SetCosentFormEffectiveDateDefaults < ActiveRecord::Migration
  def up
    GrdaWarehouse::AvailableFileTag.where(consent_form: true).update_all(requires_effective_date: true)
  end
end
