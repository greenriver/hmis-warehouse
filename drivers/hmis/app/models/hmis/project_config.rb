#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class Hmis::ProjectConfig < Hmis::HmisBase
  self.table_name = 'hmis_project_configs'

  belongs_to :project, optional: true, class_name: 'Hmis::Hud::Project'
  belongs_to :organization, optional: true, class_name: 'Hmis::Hud::Organization'
  validate :exactly_one_of_project_org_type

  def exactly_one_of_project_org_type
    count = [project, organization, project_type].map(&:blank?).count(false)
    return if count == 1 # exactly 1 of these 3 fields should be specified

    errors.add(:base, 'Specify exactly one of project, organization, and project type')
  end

  AUTO_EXIT_CONFIG = 'Hmis::ProjectAutoExitConfig'.freeze
  AUTO_ENTER_CONFIG = 'Hmis::ProjectAutoEnterConfig'.freeze
  STAFF_ASSIGNMENT_CONFIG = 'Hmis::ProjectStaffAssignmentConfig'.freeze
  TYPE_OPTIONS = [AUTO_EXIT_CONFIG, AUTO_ENTER_CONFIG, STAFF_ASSIGNMENT_CONFIG].freeze
  validates :type, inclusion: { in: TYPE_OPTIONS }

  validate :validate_config_options_json

  scope :viewable_by, ->(user) do
    # Special case this, rather than using ProjectRelated concern, because project isn't a direct relationship.
    # Project config can apply to a project, an organization, or a project type.
    # Right now we have no way to gate viewability by data source for ProjectConfigs defined by project type - TODO(#6691)
    project_ids = Hmis::Hud::Project.viewable_by(user).pluck(:id)
    organization_ids = Hmis::Hud::Organization.viewable_by(user).pluck(:id)
    where(project_id: project_ids).
      or(where(organization_id: organization_ids)).
      or(where(project_id: nil, organization_id: nil))
  end

  def validate_config_options_json
    return unless config_options

    begin
      JSON.parse(config_options)
    rescue JSON::ParserError
      errors.add(:base, 'Config options must be JSON')
    end
  end

  def options= hash
    self.config_options = hash.to_json
  end

  def options
    JSON.parse(config_options)
  rescue JSON::ParserError, TypeError
    nil
  end

  scope :for_project, ->(project) do
    where(
      arel_table[:project_id].eq(project.id).
        or(arel_table[:organization_id].eq(project.organization.id)).
        or(arel_table[:project_type].eq(project.project_type)),
    )
  end

  scope :for_projects, ->(projects) do
    Hmis::ProjectStaffAssignmentConfig.where(
      arel_table[:project_id].in(projects.map(&:id)).
        or(arel_table[:organization_id].in(projects.map { |p| p.organization.id })).
        or(arel_table[:project_type].in(projects.map(&:project_type).uniq)),
    )
  end

  scope :active, -> do
    where(enabled: true)
  end

  def self.detect_best_config_for_project(project)
    configs = for_project(project).active
    return unless configs.exists?

    # Selects the most specific rule that applies. The specificity order is Project > Org > ProjectType, so rules that
    # apply to a specific project override rules that apply to all projects in an organization, and so on.
    [
      :project_id,
      :organization_id,
      :project_type,
    ].each do |field|
      scope = configs.where.not(field => nil)
      return scope.first if scope.exists?
    end
  end
end
