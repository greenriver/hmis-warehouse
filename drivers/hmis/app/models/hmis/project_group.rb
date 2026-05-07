###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  # Criteria-based grouping of HMIS projects.
  #
  # Membership criteria is stored as JSON on the group. The current project list
  # is materialized in the hmis_project_project_groups join table, which lists
  # every project that currently belongs to each group. Call
  # maintain_project_lists! to refresh those join rows after criteria changes.
  #
  # Current uses:
  # - Access controls, where project groups can determine which projects a user
  #   can view or administer (via Collections)
  # - Workspaces, where project groups back high-level UI context switchers
  #   without changing access permissions
  #
  # Likely future uses include: reporting segmentation, form applicability,
  # and custom form-rule targeting.
  #
  # See issue #9097 for broader product context and open questions around using
  # project groups as a general HMIS grouping primitive.
  class ProjectGroup < GrdaWarehouseBase
    self.table_name = 'hmis_project_groups'
    acts_as_paranoid
    has_paper_trail
    include ::Hmis::Concerns::HmisArelHelper

    validate :data_source_must_be_hmis

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    has_and_belongs_to_many :projects, class_name: 'Hmis::Hud::Project', join_table: :hmis_project_project_groups, foreign_key: :hmis_project_group_id
    has_and_belongs_to_many :warehouse_projects, class_name: 'GrdaWarehouse::Hud::Project', join_table: :hmis_project_project_groups, foreign_key: :hmis_project_group_id
    has_many :workspaces, class_name: 'Hmis::Workspace', dependent: :restrict_with_exception, foreign_key: :hmis_project_group_id

    # GroupViewableEntities that are associated with this project group
    has_many :hmis_group_viewable_entities, -> { where(entity_type: 'Hmis::ProjectGroup') }, class_name: 'Hmis::GroupViewableEntity', foreign_key: :entity_id

    scope :viewable_by, ->(user) do
      # Only HMIS admins. We may expand visibility of project groups later with new permissions.
      return all if HmisEnforcement.hmis_admin_visible?(user)

      none
    end

    scope :editable_by, ->(user) do
      # Only HMIS admins. We may expand visibility of project groups later with new permissions.
      return all if HmisEnforcement.hmis_admin_visible?(user)

      none
    end

    # Search for project groups by group name or project name
    scope :text_search, ->(text) do
      query = text.gsub(/[^0-9a-zA-Z ]/, '')
      return none unless query.present?

      distinct.left_outer_joins(:projects).
        where(
          arel_table[:name].lower.matches("%#{query.downcase}%").
          or(p_t[:ProjectName].lower.matches("%#{query.downcase}%")),
        )
    end

    def any_inclusion_criteria?
      JSON.parse(inclusion_criteria || '{}').compact_blank.any?
    end

    def any_exclusion_criteria?
      JSON.parse(exclusion_criteria || '{}').compact_blank.any?
    end

    def parsed_inclusion_criteria= criteria
      self.inclusion_criteria = criteria.to_json
    end

    def parsed_inclusion_criteria
      @parsed_inclusion_criteria ||= Hmis::ProjectGroupCriteria.new(inclusion_criteria, data_source_id: data_source_id)
    end

    def parsed_exclusion_criteria= criteria
      self.exclusion_criteria = criteria.to_json
    end

    def parsed_exclusion_criteria
      @parsed_exclusion_criteria ||= Hmis::ProjectGroupCriteria.new(exclusion_criteria, data_source_id: data_source_id)
    end

    def self.maintain_project_lists!
      find_each(&:maintain_projects!)
    end

    def maintain_projects!
      # this directly updates the hmis_project_project_groups join table
      self.projects = Hmis::Hud::Project.hmis.where(data_source_id: data_source_id).where(id: effective_project_ids)
    end

    def effective_project_ids
      included_project_ids = parsed_inclusion_criteria.effective_project_ids
      excluded_project_ids = parsed_exclusion_criteria.effective_project_ids
      included_project_ids - excluded_project_ids
    end

    # Custom validation to ensure the data source is an HMIS data source
    def data_source_must_be_hmis
      return if data_source&.hmis?

      errors.add(:data_source, 'must be an HMIS data source')
    end

    ##
    # Marks this entity as deleted in all group viewable records.
    #
    # This prevents the entity from being viewed as part of any group.
    #
    # @return [void]
    def remove_from_group_viewable_entities!
      Hmis::GroupViewableEntity.where(
        entity_type: self.class.sti_name,
        entity_id: id,
      ).update_all(deleted_at: Time.current)
    end
  end
end
