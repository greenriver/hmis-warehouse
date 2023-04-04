###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::CustomServiceValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :ServicesID,
    :DateCreated,
    :DateUpdated,
    :RecordType,
    :TypeProvided,
    :OtherTypeProvided,
    :MovingOnOtherType,
    :SubTypeProvided,
    :FAAmount,
    :ReferralOutcome,
  ].freeze

  def configuration
    Hmis::Hud::Service.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      # Ensure that HUD services are not saved to the CustomServices table
      record.errors.add :custom_service_type, :invalid, message: 'is a HUD service' if record.service_type.hud_service?
    end
  end
end
