class Hmis::Hud::Validators::OrganizationValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  def configuration
    Hmis::Hud::Organization.hmis_configuration(version: '2022').except(*IGNORED)
  end
end
