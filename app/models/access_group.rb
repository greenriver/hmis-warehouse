###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO: START_ACL remove when ACL transition complete
class AccessGroup < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  has_many :access_group_members
  has_many :users, through: :access_group_members

  has_many :group_viewable_entities, class_name: 'GrdaWarehouse::GroupViewableEntity'
  has_many :data_sources, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::DataSource'
  has_many :organizations, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Organization'
  has_many :projects, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Project'
  has_many :project_access_groups, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::ProjectAccessGroup'
  has_many :reports, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::WarehouseReports::ReportDefinition'
  has_many :project_groups, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::ProjectGroup'
  has_many :cohorts, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Cohort'

  belongs_to :user, optional: true

  validates_presence_of :name, unless: :user_id

  scope :general, -> do
    where(user_id: nil)
  end

  scope :not_system, -> do
    where(AccessGroup.arel_table[:system].eq([]))
  end

  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    where(AccessGroup.arel_table[:system].not_eq([]))
  end

  scope :user, -> do
    joins(:user)
  end

  scope :for_user, ->(user) do
    return none unless user.id

    where(user_id: user.id)
  end

  scope :contains, ->(entity) do
    where(
      id: GrdaWarehouse::GroupViewableEntity.where(
        entity_type: entity.class.sti_name,
        entity_id: entity.id,
      ).pluck(:access_group_id),
    )
  end

  def name
    if user_id.blank?
      super
    else
      user.name
    end
  end

  def general?
    user_id.blank?
  end

  def add(users)
    self.users = (self.users + Array.wrap(users)).uniq

    users.each do |user|
      # Queue recomputation of external report access
      user.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
    end

    self.users
  end

  def remove(users)
    Array.wrap(users).each do |user|
      # Need to do this individually for paper trail to work
      self.users.destroy(user)

      # Queue recomputation of external report access
      user.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
    end
  end

  def self.delayed_system_group_maintenance(group: nil)
    delay.maintain_system_groups_no_named_arguments(group)
    Delayed::Worker.new.work_off(1_000) if Rails.env.test?
  end

  def self.maintain_system_groups_no_named_arguments(group)
    maintain_system_groups(group: group)
  end

  def self.system_groups
    {
      hmis_reports: AccessGroup.where(name: 'All HMIS Reports').first_or_create,
      health_reports: AccessGroup.where(name: 'All Health Reports').first_or_create,
      cohorts: AccessGroup.where(name: 'All Cohorts').first_or_create,
      project_groups: AccessGroup.where(name: 'All Project Groups').first_or_create,
      data_sources: AccessGroup.where(name: 'All Data Sources').first_or_create,
    }
  end

  def self.system_group(group)
    selected_group = system_groups[group]
    raise ArgumentError, "Unknown group: #{group}" unless selected_group

    selected_group
  end

  def self.maintain_system_groups(group: nil)
    system_user = User.setup_system_user
    if group.blank? || group == :reports
      # Reports
      all_reports = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled

      all_hmis_reports = system_group(:hmis_reports)
      all_hmis_reports.update(system: ['Entities'], must_exist: true)
      ids = all_reports.where(health: false).pluck(:id)
      all_hmis_reports.set_viewables({ reports: ids })

      all_health_reports = system_group(:health_reports)
      all_health_reports.update(system: ['Entities'], must_exist: true)
      ids = all_reports.where(health: true).pluck(:id)
      all_health_reports.set_viewables({ reports: ids })
      all_health_reports.add(system_user)
    end

    if group.blank? || group == :cohorts
      # Cohorts
      all_cohorts = system_group(:cohorts)
      all_cohorts.update(system: ['Entities'], must_exist: true)
      ids = GrdaWarehouse::Cohort.pluck(:id)
      all_cohorts.set_viewables({ cohorts: ids })
      all_cohorts.add(system_user)
    end

    if group.blank? || group == :project_groups
      # Project Groups
      all_project_groups = system_group(:project_groups)
      all_project_groups.update(system: ['Entities'], must_exist: true)
      ids = GrdaWarehouse::ProjectGroup.pluck(:id)
      all_project_groups.set_viewables({ project_groups: ids })
      all_project_groups.add(system_user)
    end

    if group.blank? || group == :data_sources # rubocop:disable Style/GuardClause
      # Data Sources
      all_data_sources = system_group(:data_sources)
      all_data_sources.update(system: ['Entities'], must_exist: true)
      ids = GrdaWarehouse::DataSource.pluck(:id)
      all_data_sources.set_viewables({ data_sources: ids })
      all_data_sources.add(system_user)
    end
  end

  def set_viewables(viewables) # rubocop:disable Naming/AccessorMethodName
    return unless persisted?

    GrdaWarehouse::GroupViewableEntity.transaction do
      [
        :data_sources,
        :organizations,
        :projects,
        :project_access_groups,
        :reports,
        :cohorts,
        :project_groups,
      ].each do |type|
        ids = (viewables[type] || []).map(&:to_i)
        scope = GrdaWarehouse::GroupViewableEntity.where(
          access_group_id: id,
          entity_type: viewable_types[type],
        )
        scope.where.not(entity_id: ids).destroy_all
        # Allow re-use of previous assignments
        (ids - scope.pluck(:entity_id)).each do |id|
          scope.with_deleted.
            where(entity_id: id).
            first_or_create.
            restore
        end
      end
    end
  end

  def add_viewable(viewable)
    group_viewable_entities.with_deleted.where(
      entity_type: viewable.class.sti_name,
      entity_id: viewable.id,
    ).first_or_create.restore
  end

  def remove_viewable(viewable)
    group_viewable_entities.where(
      entity_type: viewable.class.sti_name,
      entity_id: viewable.id,
    ).destroy_all
  end

  def entities_locked?
    system.include?('Entities')
  end

  # Provides a means of showing projects associated through other entities
  def associated_by(associations:)
    return [] unless associations.present?

    associations.flat_map do |association|
      case association
      when :coc_code
        coc_codes.map do |code|
          [
            code,
            GrdaWarehouse::Hud::Project.project_names_for_coc(code),
          ]
        end
      when :organization
        organizations.preload(:projects).map do |org|
          [
            org.OrganizationName,
            org.projects.map(&:ProjectName),
          ]
        end
      when :data_source
        data_sources.preload(:projects).map do |ds|
          [
            ds.name,
            ds.projects.map(&:ProjectName),
          ]
        end
      when :project_access_group
        project_access_groups.preload(:projects).map do |pag|
          [
            pag.name,
            pag.projects.map(&:ProjectName),
          ]
        end
      else
        []
      end
    end
  end

  private def viewable_types
    @viewable_types ||= {
      data_sources: 'GrdaWarehouse::DataSource',
      organizations: 'GrdaWarehouse::Hud::Organization',
      projects: 'GrdaWarehouse::Hud::Project',
      project_access_groups: 'GrdaWarehouse::ProjectAccessGroup',
      reports: 'GrdaWarehouse::WarehouseReports::ReportDefinition',
      project_groups: 'GrdaWarehouse::ProjectGroup',
      cohorts: 'GrdaWarehouse::Cohort',
    }.freeze
  end

  def associated_entity_set
    @associated_entity_set ||= group_viewable_entities.pluck(:entity_type, :entity_id).sort.to_set
  end
end
