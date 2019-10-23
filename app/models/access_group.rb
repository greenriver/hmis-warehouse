###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
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

  scope :general, -> do
    where(user_id: nil)
  end

  scope :user_specific, -> (user) do
    where(user_id: user.id)
  end

  def set_viewables(viewables)
    return unless persisted?
    GrdaWarehouse::GroupViewableEntity.transaction do
      %i( data_sources organizations projects reports cohorts project_groups ).each do |type|
        ids = ( viewables[type] || [] ).map(&:to_i)
        scope = GrdaWarehouse::GroupViewableEntity.where(access_group_id: id, entity_type: viewable_types[type])
        scope.where.not( entity_id: ids ).destroy_all
        ( ids - scope.pluck(:id) ).each{ |id| scope.where( entity_id: id ).first_or_create }
      end
    end
  end

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
      projects: 'GrdaWarehouse::Hud::Projects',
      reports: 'GrdaWarehouse::WarehouseReports::ReportDefinition',
      project_groups: 'GrdaWarehouse::ProjectGroup',
      cohorts: 'GrdaWarehouse::Cohort',
    }.freeze
  end
end