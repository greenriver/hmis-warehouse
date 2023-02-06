class Hmis::Hud::Validators::AssessmentValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Assessment.hmis_configuration(version: '2022').except(*IGNORED)
  end
end
