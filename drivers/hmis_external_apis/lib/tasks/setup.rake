###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis_external_apis:seed_ac_hmis_unit_types
desc 'Seed AC HMIS Unit Types from JSON file'
task seed_ac_hmis_unit_types: [:environment, 'log:info_to_stdout'] do
  mper_creds = ::GrdaWarehouse::RemoteCredential.active.where(slug: HmisExternalApis::AcHmis::Mper::SYSTEM_ID).first
  return unless mper_creds.present?

  # Sourced from https://docs.google.com/spreadsheets/d/1xuXIohyPguAw10KcqlqiF23qgbNzKvAR/edit#gid=844425140
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
      namespace: HmisExternalApis::AcHmis::Mper::SYSTEM_ID,
    ).first_or_create!
  end
end
