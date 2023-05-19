###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AccessGroup < ApplicationRecord
  self.table_name = :hmis_access_groups
  include RailsDrivers::Extensions
  include HmisEnabled

  acts_as_paranoid
  has_paper_trail

  has_many :access_controls, class_name: '::Hmis::AccessControl', inverse_of: :access_group
  has_many :user_group_members, through: :access_controls
  has_many :users, through: :user_group_members
  has_many :roles, through: :access_controls
  has_many :access_groups, through: :access_controls

  has_many :group_viewable_entities, class_name: 'Hmis::GroupViewableEntity'
  has_many :data_sources, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::DataSource'
  has_many :project_access_groups, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::ProjectAccessGroup'
  has_many :organizations, through: :group_viewable_entities, source: :entity, source_type: 'Hmis::Hud::Organization'
  has_many :projects, through: :group_viewable_entities, source: :entity, source_type: 'Hmis::Hud::Project'

  validates_presence_of :name

  scope :general, -> do
    all
  end

  scope :viewable, -> do
    joins(:roles).merge(Hmis::Role.with_viewable_permissions)
  end

  scope :editable, -> do
    joins(:roles).merge(Hmis::Role.with_editable_permissions)
  end

  scope :with_permissions, ->(*perms, mode: 'any') do
    joins(:roles).merge(mode == 'all' ? Hmis::Role.with_all_permissions(*perms) : Hmis::Role.with_any_permissions(*perms))
  end

  scope :contains, ->(entity) do
    where(
      id: Hmis::GroupViewableEntity.where(
        entity_type: entity.class.sti_name,
        entity_id: entity.id,
      ).pluck(:access_group_id),
    )
  end

  # TODO: Probably remove this, but it's still used below
  def self.available_scopes
    {
      'Viewable' => 'view',
      'Viewable and Editable' => 'edit',
    }.freeze
  end

  # For compatibility, doesn't actually do anything here
  def coc_codes
    []
  end

  # TODO: Probably remove this, but it's still referenced in a view
  def permission_scope
    self.class.available_scopes.invert[scope]
  end

  def set_viewables(viewables) # rubocop:disable Naming/AccessorMethodName
    return unless persisted?

    Hmis::GroupViewableEntity.transaction do
      list = [
        :data_sources,
        :organizations,
        :projects,
      ]
      list.each do |type|
        ids = (viewables[type] || []).map(&:to_i)
        scope = Hmis::GroupViewableEntity.where(
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

  # Provides a means of showing projects associated through other entities
  def associated_by(associations:)
    return [] unless associations.present?

    associations.flat_map do |association|
      case association
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

  def summary_descriptions
    data_sources = self.data_sources&.count || 0
    organizations = self.organizations&.count || 0
    projects = self.projects&.count || 0
    descriptions = []
    descriptions << "#{data_sources} #{'Data Source'.pluralize(data_sources)}" unless data_sources.zero?
    descriptions << "#{organizations} #{'Organization'.pluralize(organizations)}" unless organizations.zero?
    descriptions << "#{projects} #{'Project'.pluralize(projects)}" unless projects.zero?
    descriptions
  end

  private def viewable_types
    @viewable_types ||= {
      data_sources: 'GrdaWarehouse::DataSource',
      organizations: 'Hmis::Hud::Organization',
      projects: 'Hmis::Hud::Project',
    }.freeze
  end
end
