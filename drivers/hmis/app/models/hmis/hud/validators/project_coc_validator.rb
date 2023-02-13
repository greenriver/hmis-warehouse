class Hmis::Hud::Validators::ProjectCocValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::ProjectCoc.hmis_configuration(version: '2022').except(*IGNORED)
  end

  # TODO add validations for length of state, zip, geocode, etc.
end
