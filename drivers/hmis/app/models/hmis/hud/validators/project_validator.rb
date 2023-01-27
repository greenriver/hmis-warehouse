class Hmis::Hud::Validators::ProjectValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
  ].freeze

  def configuration
    Hmis::Hud::Project.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def validate(record)
    super(record) do
      unless skipped_attributes(record).include?(:project_type)
        record.errors.add :project_type, :required if record.project_type.nil? && record.continuum_project != 1
      end

      # End date must be after start date
      record.errors.add :operating_end_date, :invalid, message: 'must be on or after start date' if record.operating_end_date && record.operating_start_date && record.operating_end_date < record.operating_start_date
    end
  end
end
