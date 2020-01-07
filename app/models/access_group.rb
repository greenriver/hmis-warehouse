###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class AccessGroup < ActiveRecord::Base
  acts_as_paranoid

  has_many :access_group_members
  has_many :users, through: :access_group_members

  has_many :group_viewable_entities, class_name: 'GrdaWarehouse::GroupViewableEntity'
  has_many :data_sources, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::DataSource'
  has_many :organizations, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Organization'
  has_many :projects, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Hud::Project'
  has_many :reports, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::WarehouseReports::ReportDefinition'
  has_many :project_groups, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::ProjectGroup'
  has_many :cohorts, through: :group_viewable_entities, source: :entity, source_type: 'GrdaWarehouse::Cohort'

  belongs_to :user

  validates_presence_of :name, unless: :user_id

  scope :general, -> do
    where(user_id: nil)
  end

  scope :user, -> do
    joins(:users)
  end

  scope :for_user, -> (user) do
    return none unless user.id
    where(user_id: user.id)
  end

  scope :contains, -> (entity) do
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

  def add(user)
    access_group_members.where(user_id: user.id).first_or_create
  end

  def remove(user)
    access_group_members.where(user_id: user.id).destroy_all
  end

  def set_viewables(viewables)
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
        ids = ( viewables[type] || [] ).map(&:to_i)
        scope = GrdaWarehouse::GroupViewableEntity.where(
          access_group_id: id,
          entity_type: viewable_types[type],
        )
        scope.where.not( entity_id: ids ).destroy_all
        # Allow re-use of previous assignments
        ( ids - scope.pluck(:id) ).each do |id|
          scope.with_deleted.
            where( entity_id: id ).
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
        when :coc_code
          coc_codes.map do |code|
            [
              code,
              GrdaWarehouse::Hud::Project.project_names_for_coc(code)
            ]
          end
        when :organization
          organizations.preload(:projects).map do |org|
            [
              org.OrganizationName,
              org.projects.map(&:ProjectName)
            ]
          end
        when :data_source
          data_sources.preload(:projects).map do |ds|
            [
              ds.name,
              ds.projects.map(&:ProjectName)
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