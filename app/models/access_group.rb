###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessGroup < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  has_many :access_group_members
  has_many :users, through: :access_group_members

  has_many :group_viewable_entities, class_name: 'GrdaWarehouse::GroupViewableEntity'
  has_many :data_sources, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::DataSource'
  has_many :organizations, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Organization'
  has_many :projects, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Project'
  has_many :reports, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::WarehouseReports::ReportDefinition'
  has_many :project_groups, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::ProjectGroup'
  has_many :cohorts, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Cohort'

  belongs_to :user, optional: true

  validates_presence_of :name, unless: :user_id

  scope :general, -> do
    where(user_id: nil)
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
  end

  def remove(users)
    self.users = (self.users - Array.wrap(users))
  end

  def self.delayed_system_group_maintenance(group: nil)
    delay.maintain_system_groups(group: group)
    Delayed::Worker.new.work_off if Rails.env.test?
  end

  def self.maintain_system_groups(group: nil)
    system_user = User.setup_system_user
    if group.blank? || group == :reports
      # Reports
      all_reports = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled

      all_hmis_reports = AccessGroup.where(name: 'All HMIS Reports').first_or_create
      all_hmis_reports.update(system: ['Entities'], must_exist: true)
      ids = all_reports.where(health: false).pluck(:id)
      all_hmis_reports.set_viewables({ reports: ids })

      all_health_reports = AccessGroup.where(name: 'All Health Reports').first_or_create
      all_health_reports.update(system: ['Entities'], must_exist: true)
      ids = all_reports.where(health: true).pluck(:id)
      all_health_reports.set_viewables({ reports: ids })
      all_health_reports.add(system_user)
    end

    if group.blank? || group == :cohorts
      # Cohorts
      all_cohorts = AccessGroup.where(name: 'All Cohorts').first_or_create
      all_cohorts.update(system: ['Entities'], must_exist: true)
      ids = GrdaWarehouse::Cohort.pluck(:id)
      all_cohorts.set_viewables({ cohorts: ids })
      all_cohorts.add(system_user)
    end

    if group.blank? || group == :project_groups
      # Project Groups
      all_project_groups = AccessGroup.where(name: 'All Project Groups').first_or_create
      all_project_groups.update(system: ['Entities'], must_exist: true)
      ids = GrdaWarehouse::ProjectGroup.pluck(:id)
      all_project_groups.set_viewables({ project_groups: ids })
      all_project_groups.add(system_user)
    end

    if group.blank? || group == :data_sources # rubocop:disable Style/GuardClause
      # Data Sources
      all_data_sources = AccessGroup.where(name: 'All Data Sources').first_or_create
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
      reports: 'GrdaWarehouse::WarehouseReports::ReportDefinition',
      project_groups: 'GrdaWarehouse::ProjectGroup',
      cohorts: 'GrdaWarehouse::Cohort',
    }.freeze
  end
end
