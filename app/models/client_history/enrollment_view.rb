###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientHistory::EnrollmentView
  attr_accessor :enrollment, :user
  # @param enrollment [Object] the enrollment record for the client
  # @param user [Object] the user accessing this view, used to correctly limit returned data
  def initialize(enrollment:, user:)
    self.enrollment = enrollment
    self.user = user
  end

  private def affiliated_residential_projects
    @affiliated_residential_projects ||= GrdaWarehouse::Hud::Affiliation.preload(:project, :residential_project).map do |affiliation|
      [
        [affiliation.project&.ProjectID, affiliation.project&.data_source_id],
        affiliation.residential_project&.name(user),
      ]
    end.group_by(&:first)

    key = [enrollment[:ProjectID], enrollment[:data_source_id]]
    @affiliated_residential_projects[key]&.map(&:last) || []
  end

  private def affiliated_projects
    @affiliated_projects ||= GrdaWarehouse::Hud::Affiliation.preload(:project, :residential_project).
      map do |affiliation|
      [
        [affiliation.residential_project&.ProjectID, affiliation.residential_project&.data_source_id],
        affiliation.project&.name(user),
      ]
    end.group_by(&:first)

    key = [enrollment[:ProjectID], enrollment[:data_source_id]]
    @affiliated_projects[key]&.map(&:last) || []
  end

  private def affiliated_projects_str_for_enrollment
    project_names = affiliated_projects
    return nil unless project_names.any?

    "Affiliated with #{project_names.to_sentence}"
  end

  private def residential_projects_str_for_enrollment
    project_names = affiliated_residential_projects
    return nil unless project_names.any?

    "Affiliated with #{project_names.to_sentence}"
  end

  def program_tooltip_data_for_enrollment
    affiliated_projects_str = affiliated_projects_str_for_enrollment
    residential_projects_str = residential_projects_str_for_enrollment
    # only show tooltip if there are projects to list
    if affiliated_projects_str.present? || residential_projects_str.present?
      title = [affiliated_projects_str, residential_projects_str].compact.join("\n")
      {
        toggle: :tooltip,
        title: title,
      }
    else
      {}
    end
  end
end
