###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::ClientValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :Gender,
    :Race,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Client.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      record.errors.add :gender, :required if !skipped_attributes(record).include?(:gender) && ::HudUtility.gender_id_to_field_name.except(8, 9, 99).values.any? { |field| record.send(field).nil? }
      record.errors.add :race, :required if !skipped_attributes(record).include?(:race) && ::HudUtility.races.except('RaceNone').keys.any? { |field| record.send(field).nil? }

      # Validate exactly 1 primary name
      if record.names.any?
        num_primary_names = record.names.map(&:primary).count(true)
        record.errors.add :names, :invalid, full_message: 'One primary name is required' if num_primary_names != 1
      end
    end
  end
end
