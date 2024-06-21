###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HMIS uses similar but separate permissions system from the warehouse
# See drivers/hmis/doc/PERMISSIONS.md

class Hmis::AccessGroup < ApplicationRecord
  self.table_name = :hmis_access_groups
  include RailsDrivers::Extensions
  include HmisEnabled

  acts_as_paranoid
  has_paper_trail

  has_many :access_controls, class_name: '::Hmis::AccessControl', inverse_of: :access_group
  has_many :users, through: :access_controls

  has_many :group_viewable_entities, class_name: 'Hmis::GroupViewableEntity', foreign_key: :collection_id
  has_many :data_sources, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::DataSource'
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

  scope :contains, ->(entity) do
    where(
      id: Hmis::GroupViewableEntity.where(
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

  # For compatibility, doesn't actually do anything here
  def coc_codes
    []
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
          collection_id: id,
          entity_type: viewable_types[type],
        )
        scope.where.not(entity_id: ids).destroy_all
        # Allow re-use of previous assignments
        (ids - scope.pluck(:entity_id)).each do |id|
          gve = scope.with_deleted.where(entity_id: id).first_or_create!
          gve.restore if gve.deleted?
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
      else
        []
      end
    end
  end

  def clean_entity_type(key)
    entity_types.keys.detect { |e| e == key.to_sym } || entity_types.keys.first
  end

  def entity_title(key)
    entity_types[key.to_sym] || key
  end

  def partial_for(key)
    "hmis_admin/groups/entities/#{clean_entity_type(key)}"
  end

  def entity_types
    {
      data_sources: 'Data Sources',
      organizations: 'Organizations',
      projects: 'Projects',
    }.freeze
  end

  def relevant_entity_types
    return entity_types if collection_type.blank?

    relevant_types = [
      :data_sources,
      :organizations,
      :projects,
    ]
    entity_types.slice(*relevant_types)
  end

  def overall_project_count
    @overall_project_count ||= Set.new.tap do |ids|
      ids.merge projects.pluck(:id)
      data_sources.each do |ds|
        ids.merge ds.projects.pluck(:id)
      end
      organizations.each do |o|
        ids.merge o.projects.pluck(:id)
      end
    end.count
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
