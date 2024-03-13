###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Collection < ApplicationRecord
  include UserPermissionCache

  acts_as_paranoid
  has_paper_trail

  after_save :invalidate_user_permission_cache

  has_many :access_controls
  has_many :users, through: :access_controls

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
    not_hidden.where(user_id: nil)
  end

  scope :not_system, -> do
    not_hidden.where(Collection.arel_table[:system].eq([]))
  end

  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    where(Collection.arel_table[:system].not_eq([]))
  end

  scope :hidden, -> do
    system.where.contains(system: 'Hidden')
  end

  scope :not_hidden, -> do
    where.not(id: hidden.select(:id))
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
      ).pluck(:collection_id),
    )
  end

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(
      arel_table[:name].matches(query).
      or(arel_table[:description].matches(query)),
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

  def legacy?
    collection_type.blank?
  end

  def describe_type
    return 'Any' if collection_type.blank?

    collection_type
  end

  def self.available_collection_types
    [
      'Projects',
      'Project Groups',
      'Reports',
      'Cohorts',
    ].freeze
  end

  def clean_entity_type(key)
    entity_types.keys.detect { |e| e == key.to_sym } || entity_types.keys.first
  end

  def entity_title(key)
    entity_types[key.to_sym] || key
  end

  def partial_for(key)
    "admin/collections/entities/#{clean_entity_type(key)}"
  end

  def entity_types
    {
      data_sources: 'Data Sources',
      organizations: 'Organizations',
      project_access_groups: 'Project Groups', # access to projects through project groups
      coc_codes: 'CoC Codes',
      projects: 'Projects',
      reports: 'Reports',
      cohorts: 'Cohorts',
      project_groups: 'Project Groups', # access to project groups
    }.freeze
  end

  def relevant_entity_types
    return entity_types if collection_type.blank?

    relevant_types = case collection_type
    when 'Projects'
      [
        :data_sources,
        :organizations,
        :project_access_groups,
        :coc_codes,
        :projects,
      ]
    when 'Project Groups'
      [
        :project_groups,
      ]
    when 'Reports'
      [
        :reports,
      ]
    when 'Cohorts'
      [
        :cohorts,
      ]
    end
    entity_types.slice(*relevant_types)
  end

  def overall_project_count
    projects.count
  end

  def project_duplicated(project_id, entity_type)
    return unless project_overlap[project_id].present?

    project_overlap[project_id].map do |et, sources|
      next if et == entity_type # ignore ourselves
      next unless sources.present?

      "#{entity_title(et)}: #{sources.join(', ')}"
    end.compact.join('<br />')
  end

  private def project_overlap
    @project_overlap ||= {}.tap do |po|
      data_sources.each do |entity|
        entity.projects.pluck(:id).each do |p_id|
          po[p_id] ||= { data_sources: [], organizations: [], project_access_groups: [], coc_codes: [], projects: [] }
          po[p_id][:data_sources] << entity.name
        end
      end
      organizations.each do |entity|
        entity.projects.pluck(:id).each do |p_id|
          po[p_id] ||= { data_sources: [], organizations: [], project_access_groups: [], coc_codes: [], projects: [] }
          po[p_id][:organizations] << entity.name
        end
      end
      project_groups.each do |entity|
        entity.projects.pluck(:id).each do |p_id|
          po[p_id] ||= { data_sources: [], organizations: [], project_access_groups: [], coc_codes: [], projects: [] }
          po[p_id][:organizations] << entity.name
        end
      end
      coc_codes.each do |code|
        GrdaWarehouse::Hud::Project.in_coc(coc_code: code).pluck(:id).each do |p_id|
          po[p_id] ||= { data_sources: [], organizations: [], project_access_groups: [], coc_codes: [], projects: [] }
          po[p_id][:coc_codes] << code
        end
      end
      projects.each do |entity|
        p_id = entity.id
        po[p_id] ||= { data_sources: [], organizations: [], project_access_groups: [], coc_codes: [], projects: [] }
        po[p_id][:projects] << entity.name
      end
    end
  end

  def project_count_from(type)
    case type.to_sym
    when :data_sources, :organizations, :project_access_groups
      public_send(type).map { |entity_type| entity_type.projects.size }.sum
    when :projects
      projects.count
    when :coc_codes
      GrdaWarehouse::Hud::Project.in_coc(coc_code: coc_codes).distinct.count
    else
      0
    end
  end

  def add(users)
    self.users = (self.users + Array.wrap(users)).uniq
  end

  def remove(users)
    Array.wrap(users).each do |u|
      # Need to do this individually for paper trail to work
      self.users.destroy(u)
    end
  end

  def self.delayed_system_group_maintenance(group: nil)
    delay.maintain_system_groups_no_named_arguments(group)
    Delayed::Worker.new.work_off(1_000) if Rails.env.test?
  end

  def self.maintain_system_groups_no_named_arguments(group)
    maintain_system_groups(group: group)
  end

  def self.system_collections
    {
      hmis_reports: Collection.where(name: 'All HMIS Reports', must_exist: true).first_or_create { |g| g.system = ['Entities'] },
      health_reports: Collection.where(name: 'All Health Reports', must_exist: true).first_or_create { |g| g.system = ['Entities'] },
      cohorts: Collection.where(name: 'All Cohorts', must_exist: true).first_or_create { |g| g.system = ['Entities'] },
      project_groups: Collection.where(name: 'All Project Groups', must_exist: true).first_or_create { |g| g.system = ['Entities'] },
      data_sources: Collection.where(name: 'All Data Sources', must_exist: true).first_or_create { |g| g.system = ['Entities'] },
      system_user: Collection.where(name: 'Hidden System Group', must_exist: true).first_or_create { |g| g.system = ['Entities', 'Hidden'] },
      window_data_sources: Collection.where(name: 'Window Data Sources', must_exist: true).first_or_create { |g| g.system = ['Entities'] },
    }
  end

  def self.system_collection(collection)
    selected_collection = system_collections[collection]
    raise ArgumentError, "Unknown collection: #{collection}" unless selected_collection

    selected_collection
  end

  def self.maintain_system_groups(group: nil)
    # First or Create the following:
    # setup system role
    # setup system collections (with all items currently in system collections below)
    # setup system user group
    # setup system ACL with system role, system collections, system user
    # Then add all ids for each category with set_viewables
    User.clear_cached_permissions
    system_user_role = Role.system_user_role
    system_user_access_group = system_collection(:system_user)
    system_user_group = UserGroup.system_user_group
    AccessControl.where(role_id: system_user_role.id, collection_id: system_user_access_group.id, user_group_id: system_user_group.id).first_or_create

    if group.blank? || group == :reports
      # Reports
      all_reports = GrdaWarehouse::WarehouseReports::ReportDefinition.enabled

      all_report_ids = []
      all_hmis_reports = system_collection(:hmis_reports)
      ids = all_reports.where(health: false).pluck(:id)
      all_hmis_reports.set_viewables({ reports: ids })
      all_report_ids += ids

      all_health_reports = system_collection(:health_reports)
      ids = all_reports.where(health: true).pluck(:id)
      all_health_reports.set_viewables({ reports: ids })
      all_report_ids += ids
      system_user_access_group.set_viewables({ reports: all_report_ids })
    end

    if group.blank? || group == :cohorts
      # Cohorts
      all_cohorts = system_collection(:cohorts)
      ids = GrdaWarehouse::Cohort.pluck(:id)
      all_cohorts.set_viewables({ cohorts: ids })
      system_user_access_group.set_viewables({ cohorts: ids })
    end

    if group.blank? || group == :project_groups
      # Project Groups
      all_project_groups = system_collection(:project_groups)
      ids = GrdaWarehouse::ProjectGroup.pluck(:id)
      all_project_groups.set_viewables({ project_groups: ids })
      system_user_access_group.set_viewables({ project_groups: ids })
    end

    if group.blank? || group == :data_sources
      # Data Sources
      all_data_sources = system_collection(:data_sources)
      ids = GrdaWarehouse::DataSource.pluck(:id)
      all_data_sources.set_viewables({ data_sources: ids })
      system_user_access_group.set_viewables({ data_sources: ids })
    end

    if group.blank? || group == :window_data_sources # rubocop:disable Style/GuardClause
      # Window Data Sources
      window_data_sources = system_collection(:window_data_sources)
      ids = GrdaWarehouse::DataSource.visible_in_window.pluck(:id)
      window_data_sources.set_viewables({ data_sources: ids })
    end
  end

  # Replace all viewables with those provided
  # @param [Hash] viewables Of the format { reports: [1, 2, 3], projects: [4, 5] }
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
          collection_id: id,
          entity_type: viewable_types[type],
        )
        scope.where.not(entity_id: ids).destroy_all
        # Allow re-use of previous assignments
        (ids - scope.pluck(:entity_id)).each do |id|
          gve = scope.with_deleted.
            where(entity_id: id).
            first_or_initialize do |g|
              # set access group id because it is required, but no longer used
              g.access_group_id = 0
              g.collection_id = self.id
            end
          gve.restore if gve.deleted?
          gve.save!
        end
      end
    end
  end

  def add_viewable(viewable)
    gve = group_viewable_entities.with_deleted.where(
      entity_type: viewable.class.sti_name,
      entity_id: viewable.id,
    ).first_or_initialize do |g|
      # set access group id because it is required, but no longer used
      g.access_group_id = 0
    end
    gve.restore if gve.deleted?
    gve.save!
    gve
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

  def all_associated_entities
    {
      'CoC Codes' => coc_codes.flat_map do |code|
        [code] +
          GrdaWarehouse::Hud::Project.project_names_for_coc(code).map do |name|
            " – #{name} (in #{code})"
          end
      end,
      'Project Groups' => project_access_groups.preload(:projects).map(&:name),
      'Data Sources' => data_sources.map(&:name),
      'Organizations' => organizations.map(&:OrganizationName),
      'Projects' => projects.map(&:ProjectName),
      'Cohorts' => cohorts.map(&:name),
      'Reports' => reports.map(&:name),
    }
  end

  def associated_entity_set
    @associated_entity_set ||= group_viewable_entities.pluck(:entity_type, :entity_id).sort.to_set
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
end
