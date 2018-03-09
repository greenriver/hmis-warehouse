class AddDefaultsToClientDetails < ActiveRecord::Migration
  def up
    config = GrdaWarehouse::Config.first
    details = [
     :disability_verified_on,
     :housing_release_status,
     :full_housing_release,
     :limited_cas_release,
     :sync_with_cas,
     :dmh_eligible,
     :va_eligible,
     :hues_eligible,
     :hiv_positive,
     :chronically_homeless_for_cas,
     :us_citizen,
     :asylee,
     :ineligible_immigrant,
     :lifetime_sex_offender,
     :meth_production_conviction,
     :family_member,
     :child_in_household,
     :ha_eligible,
     :cspech_eligible
    ]
    if config
      config.update(client_details: details.map(&:to_s))
    end
  end
  def down
    config = GrdaWarehouse::Config.first
    if config
      config.update(client_details: [])
    end
  end
end
