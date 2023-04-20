###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis_external_apis:seed_ac_hmis_unit_types
desc 'Seed AC HMIS Unit Types from JSON file'
task seed_ac_hmis_unit_types: [:environment, 'log:info_to_stdout'] do
  mper_creds = GrdaWarehouse::RemoteCredentials::Smtp.where(slug: 'mper').first!
  unit_types = JSON.parse(File.read('drivers/hmis_external_apis/lib/data/ac_hmis/unit_types.json'))
  unit_types.each do |type|
    unit_type = Hmis::UnitType.where(
      description: type['name'],
      bed_type: Hmis::UnitType.bed_types[type['hud_bed_type'].underscore],
    ).first_or_create!

    # Linking these to MPER Credentials even though we're not pulling them directly from MPER
    HmisExternalApis::ExternalId.where(
      value: type['external_id'].to_s,
      remote_credential: mper_creds,
      source: unit_type,
    ).first_or_create!
  end
end
