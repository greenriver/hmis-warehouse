###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# these are also sometimes called agencies
module GrdaWarehouse::Hud
  class Organization < Base
    include ArelHelper
    include HudSharedScopes
    include ::HmisStructure::Organization
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Organization'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    has_many :projects, **hud_assoc(:OrganizationID, 'Project'), inverse_of: :organization
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :organizations, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :projects, optional: true
    belongs_to :data_source, inverse_of: :organizations

    has_many :service_history_enrollments, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID], inverse_of: :organization
    has_many :contacts, class_name: 'GrdaWarehouse::Contact::Organization', foreign_key: :entity_id

    accepts_nested_attributes_for :projects

    # NOTE: you need to add a distinct to this or group it to keep from getting repeats
    scope :residential, -> do
      joins(:projects).where(
        Project.arel_table[:ProjectType].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS),
      )
    end

    scope :confidential, -> do
      where(confidential: true)
    end

    scope :non_confidential, -> do
      where(confidential: false)
    end

    scope :dmh, -> do
      where(dmh: true)
    end
    scope :viewable_by, ->(user, permission: :can_view_projects) do
      return none unless user&.send("#{permission}?")

      ids = organization_ids_viewable_by(user, permission: permission)
      # If have a set (not a nil) and it's empty, this user can't access any projects
      return none if ids.is_a?(Set) && ids.empty?

      where(id: ids)
    end

    scope :editable_by, ->(user, permission: :can_edit_organiztions) do
      return none unless user&.send("#{permission}?")

      ids = organization_ids_from_viewable_entities(user, permission)
      ids += organization_ids_from_data_sources(user, permission)
      # If have a set (not a nil) and it's empty, this user can't access any projects
      return none if ids.is_a?(Set) && ids.empty?

      where(id: ids)
    end

    def self.organization_ids_viewable_by(user, permission: :can_view_projects)
      return Set.new unless user&.send("#{permission}?")

      ids = Set.new
      ids += organization_ids_from_viewable_entities(user, permission)
      ids += organization_ids_from_data_sources(user, permission)
      ids += organization_ids_from_projects(user, permission)
      ids
    end

    def self.organization_ids_from_viewable_entities(user, permission)
      return [] unless user.present?
      return [] unless user.send("#{permission}?")

      group_ids = user.entity_groups_for_permission(permission)
      return [] if group_ids.empty?

      GrdaWarehouse::GroupViewableEntity.where(
        access_group_id: group_ids,
        entity_type: 'GrdaWarehouse::Hud::Organization',
      ).pluck(:entity_id)
    end

    def self.organization_ids_from_entity_type(user, permission, entity_class)
      return [] unless user.present?
      return [] unless user.send("#{permission}?")

      group_ids = user.entity_groups_for_permission(permission)
      return [] if group_ids.empty?

      entity_class.where(
        id: GrdaWarehouse::GroupViewableEntity.where(
          access_group_id: group_ids,
          entity_type: entity_class.sti_name,
        ).select(:entity_id),
      ).joins(:organizations).pluck(o_t[:id])
    end

    def self.organization_ids_from_projects(user, permission)
      return [] unless user.present?
      return [] unless user.send("#{permission}?")

      group_ids = user.entity_groups_for_permission(permission)
      return [] if group_ids.empty?

      GrdaWarehouse::Hud::Project.where(
        id: GrdaWarehouse::GroupViewableEntity.where(
          access_group_id: group_ids,
          entity_type: GrdaWarehouse::Hud::Project.sti_name,
        ).select(:entity_id),
      ).joins(:organization).pluck(o_t[:id])
    end

    def self.organization_ids_from_data_sources(user, permission)
      organization_ids_from_entity_type(user, permission, GrdaWarehouse::DataSource)
    end

    def for_export
      row = HmisCsvTwentyTwentyTwo::Exporter::Organization::Overrides.apply_overrides(self, options: { confidential: false })
      row = HmisCsvTwentyTwentyTwo::Exporter::Organization.adjust_keys(row)
      row
    end

    def self.confidential_organization_name
      'Confidential Organization'
    end

    def self.names
      select(:OrganizationID, :OrganizationName).distinct.pluck(:OrganizationName, :OrganizationID)
    end

    def project_names
      projects.order(ProjectName: :asc).pluck(:ProjectName)
    end

    alias_attribute :name, :OrganizationName

    def name(user = nil, ignore_confidential_status: false)
      if ignore_confidential_status || user&.can_view_confidential_project_names?
        self.OrganizationName
      else
        safe_organization_name
      end
    end

    def safe_organization_name
      if confidential?
        self.class.confidential_organization_name
      else
        self.OrganizationName
      end
    end

    def self.text_search(text)
      return none unless text.present?

      query = "%#{text}%"

      where(
        arel_table[:OrganizationName].matches(query),
      )
    end

    def self.confidential_org?(organization_id, data_source_id)
      confidential_organization_ids = Rails.cache.fetch('confidential_organization_ids', expires_in: 2.minutes) do
        confidential.pluck(:OrganizationID, :data_source_id).to_set
      end
      confidential_organization_ids.include?([organization_id, data_source_id])
    end

    def self.options_for_select user:
      # don't cache this, it's a class method
      @options = begin
        options = {}
        scope = viewable_by(user)
        scope = scope.where(confidential: false) unless user.can_view_confidential_project_names?
        scope.joins(:data_source).
          order(ds_t[:name].asc, OrganizationName: :asc).
          pluck(ds_t[:name].as('ds_name'), :OrganizationName, :id).each do |ds, org_name, id|
            options[ds] ||= []
            options[ds] << [org_name, id]
          end
        options
      end
    end

    def destroy_dependents!
      projects.map(&:destroy_dependents!)
      projects.update_all(DateDeleted: Time.current, source_hash: nil)
    end
  end
end
