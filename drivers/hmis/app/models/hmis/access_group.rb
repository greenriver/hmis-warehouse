###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AccessGroup < ApplicationRecord
  self.table_name = :hmis_access_groups
  include RailsDrivers::Extensions
  include HmisEnabled

  acts_as_paranoid
  has_paper_trail

  has_many :access_group_members
  has_many :users, through: :access_group_members

  has_many :group_viewable_entities, class_name: 'GrdaWarehouse::GroupViewableEntity'
  has_many :data_sources, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::DataSource'
  has_many :organizations, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Organization'
  has_many :projects, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Project'
  has_many :project_access_groups, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::ProjectAccessGroup'

  validates_presence_of :name

  scope :contains, ->(entity) do
    where(
      id: GrdaWarehouse::GroupViewableEntity.where(
        entity_type: entity.class.sti_name,
        entity_id: entity.id,
      ).pluck(:access_group_id),
    )
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

  def set_viewables(viewables) # rubocop:disable Naming/AccessorMethodName
    return unless persisted?

    GrdaWarehouse::GroupViewableEntity.transaction do
      list = [
        :data_sources,
        :organizations,
        :projects,
        :project_access_groups,
      ]
      list.each do |type|
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

  private def viewable_types
    @viewable_types ||= {
      data_sources: 'GrdaWarehouse::DataSource',
      organizations: 'GrdaWarehouse::Hud::Organization',
      projects: 'GrdaWarehouse::Hud::Project',
      project_access_groups: 'GrdaWarehouse::ProjectAccessGroup',
    }.freeze
  end
end
