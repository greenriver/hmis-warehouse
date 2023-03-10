class Hmis::Hud::Validators::ProjectValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Project.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def hmis_validate(project, ignore_warnings: false)
    errors = HmisErrors::Errors.new

    # If project end date is changing
    if project.operating_end_date_changed?
      open_enrollments = Hmis::Hud::Enrollment.open_on_date(project.operating_end_date).
        in_project_including_wip(project.id, project.project_id)
      errors.add :base, :information, severity: :warning, full_message: "Project has #{open_enrollments.count} open #{'enrollment'.pluralize(open_enrollments.count)} on the selected end date." if open_enrollments.any?
    end

    # If project is being "closed" for the first time
    if project.operating_end_date_was.nil? && project.operating_end_date.present?
      funder_count = project.funders.where(end_date: nil).count
      inventory_count = project.inventories.where(inventory_end_date: nil).count
      errors.add :base, :information, severity: :warning, full_message: "#{funder_count} open #{'funder'.pluralize(funder_count)} will be closed." if funder_count.positive?
      errors.add :base, :information, severity: :warning, full_message: "#{inventory_count} open inventory #{'record'.pluralize(inventory_count)} will be closed." if inventory_count.positive?
    end

    return errors.errors.reject(&:warning?) if ignore_warnings

    errors.errors
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
