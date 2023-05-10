###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::ProjectValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
  ].freeze

  def configuration
    Hmis::Hud::Project.hmis_configuration(version: '2022').except(*IGNORED)
  end

  def self.open_enrollments_message(num)
    "Project has #{num} open #{'enrollment'.pluralize(num)} on the selected end date."
  end

  def self.open_funders_message(num)
    "#{num} open #{'funder'.pluralize(num)} will be closed."
  end

  def self.open_inventory_message(num)
    "#{num} open inventory #{'record'.pluralize(num)} will be closed."
  end

  def self.hmis_validate(project, **_)
    errors = HmisErrors::Errors.new

    # If project end date is changing
    if project.operating_end_date.present? && project.operating_end_date_changed?
      open_enrollments = project.enrollments_including_wip.open_on_date(project.operating_end_date)
      errors.add :base, :information, severity: :warning, full_message: open_enrollments_message(open_enrollments.count) if open_enrollments.any?
    end

    # If project is being "closed" for the first time
    if project.operating_end_date_was.nil? && project.operating_end_date.present?
      funder_count = project.funders.where(end_date: nil).count
      inventory_count = project.inventories.where(inventory_end_date: nil).count
      errors.add :base, :information, severity: :warning, full_message: open_funders_message(funder_count) if funder_count.positive?
      errors.add :base, :information, severity: :warning, full_message: open_inventory_message(inventory_count) if inventory_count.positive?
    end

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
