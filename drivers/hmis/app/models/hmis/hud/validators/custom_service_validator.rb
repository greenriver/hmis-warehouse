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
      # TODO: what happens when a service type switches over from being non-HUD to being linked to HUD? we need to disallow that?
      # record.errors.add :service_type, :invalid, full_message: 'Cannot save HUD Service to CustomService table' if record.service_type.hud_service?
    end
  end
end
