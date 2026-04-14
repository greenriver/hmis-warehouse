###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ProjectConfig < Hmis::HmisBase
  self.table_name = 'hmis_project_configs'

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :project, optional: true, class_name: 'Hmis::Hud::Project'
  belongs_to :organization, optional: true, class_name: 'Hmis::Hud::Organization'
  validate :exactly_one_of_project_org_type

  def exactly_one_of_project_org_type
    count = [project, organization, project_type].map(&:blank?).count(false)
    return if count == 1 # exactly 1 of these 3 fields should be specified

    errors.add(:base, 'Specify exactly one of project, organization, and project type')
  end

  AUTO_EXIT_CONFIG = 'Hmis::ProjectAutoExitConfig'
  AUTO_ENTER_CONFIG = 'Hmis::ProjectAutoEnterConfig'
  STAFF_ASSIGNMENT_CONFIG = 'Hmis::ProjectStaffAssignmentConfig'
  CE_CONFIG = 'Hmis::ProjectCeConfig'
  SENDS_DIRECT_CE_REFERRALS_CONFIG = 'Hmis::ProjectSendsDirectCeReferralsConfig'

  CONFIG_TYPE_FACTORIES = {
    'AUTO_EXIT' => AUTO_EXIT_CONFIG,
    'AUTO_ENTER' => AUTO_ENTER_CONFIG,
    'STAFF_ASSIGNMENT' => STAFF_ASSIGNMENT_CONFIG,
    'COORDINATED_ENTRY' => CE_CONFIG,
    'SENDS_DIRECT_CE_REFERRALS' => SENDS_DIRECT_CE_REFERRALS_CONFIG,
  }.freeze

  validates :type, inclusion: { in: CONFIG_TYPE_FACTORIES.values }

  validate :validate_config_options_json
  validate :validate_consistent_data_source

  scope :viewable_by, ->(user) do
    return none unless user.policy_for(Hmis::ProjectConfig, policy_type: :project_config).can_manage?

    where(data_source_id: user.hmis_data_source_id)
  end

  def validate_config_options_json
    return unless config_options

    begin
      JSON.parse(config_options)
    rescue JSON::ParserError
      errors.add(:base, 'Config options must be JSON')
    end
  end

  # TODO(#7960) - update to store json blob instead of jsonified string; will require migrating existing data
  def options= hash
    self.config_options = hash.to_json
  end

  def options
    JSON.parse(config_options)
  rescue JSON::ParserError, TypeError
    nil
  end

  scope :for_project, ->(project) do
    where(data_source_id: project.data_source_id).where(
      arel_table[:project_id].eq(project.id).
        or(arel_table[:organization_id].eq(project.organization.id)).
        or(arel_table[:project_type].eq(project.project_type)),
    )
  end

  scope :for_projects, ->(projects) do
    return none if projects.empty?

    # Expect all projects to be from the same data source; raise otherwise
    data_source_id = projects.pluck(:data_source_id).uniq.sole

    where(data_source_id: data_source_id).where(
      arel_table[:project_id].in(projects.map(&:id)).
        or(arel_table[:organization_id].in(projects.map { |p| p.organization.id })).
        or(arel_table[:project_type].in(projects.map(&:project_type).uniq)),
    )
  end

  scope :active, -> do
    where(enabled: true)
  end

  # Filter by GraphQL config type (eg 'AUTO_ENTER', 'AUTO_EXIT', etc.)
  scope :with_config_type, ->(config_type) do
    types = Array.wrap(config_type).map do |type|
      CONFIG_TYPE_FACTORIES[type.to_s] || raise("Unknown config type: #{type}")
    end
    where(type: types)
  end

  def self.config_factory(config_type)
    CONFIG_TYPE_FACTORIES.fetch(config_type).constantize.new
  end

  def self.apply_filters(input)
    Hmis::Filter::ProjectConfigFilter.new(input).filter_scope(self)
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

  private

  def validate_consistent_data_source
    errors.add(:base, 'Data source must be the same as project') if project.present? && data_source != project.data_source
    errors.add(:base, 'Data source must be the same as organization') if organization.present? && data_source != organization.data_source
  end

  def set_config_option(key, value)
    new_options = { key => value }.stringify_keys
    merged_options = options ? options.merge(new_options) : new_options
    self.config_options = merged_options.to_json
  end
end
