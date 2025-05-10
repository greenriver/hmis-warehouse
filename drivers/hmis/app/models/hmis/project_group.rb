###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class ProjectGroup < GrdaWarehouseBase
    self.table_name = 'hmis_project_groups'
    acts_as_paranoid
    has_paper_trail
    include ::Hmis::Concerns::HmisArelHelper

    validates :name, presence: true, uniqueness: true
    # validate :validate_criteria_json
    # TODO validates configuration shape
    # TODO validates project_must_belong_to_hmis_data_source

    has_and_belongs_to_many :projects, class_name: 'Hmis::Hud::Project', join_table: :hmis_project_project_groups, foreign_key: :hmis_project_group_id

    # GroupViewableEntities that are associated with this project group
    has_many :hmis_group_viewable_entities, -> { where(entity_type: 'Hmis::ProjectGroup') }, class_name: 'Hmis::GroupViewableEntity', foreign_key: :entity_id

    # NOTE: these are in the app DB
    has_many :hmis_access_groups, through: :hmis_group_viewable_entities
    has_many :hmis_access_controls, through: :hmis_access_groups

    scope :viewable_by, ->(user) do
      # We will likely expand visibility of project groups later, for now only HMIS admins can see them.
      return all if HmisEnforcement.hmis_admin_visible?(user)

      none
    end

    scope :editable_by, ->(user) do
      # We may expand editability of project groups later, for now only HMIS admins can edit them.
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

    def parsed_inclusion_criteria= criteria
      self.inclusion_criteria = criteria.to_json
    end

    def parsed_inclusion_criteria
      @parsed_inclusion_criteria ||= Hmis::ProjectGroupCriteria.new(inclusion_criteria)
    end

    def parsed_exclusion_criteria= criteria
      self.exclusion_criteria = criteria.to_json
    end

    def parsed_exclusion_criteria
      @parsed_exclusion_criteria ||= Hmis::ProjectGroupCriteria.new(exclusion_criteria)
    end

    def self.maintain_project_lists!
      find_each(&:maintain_projects!)
    end

    def maintain_projects!
      # this directly updates the hmis_project_project_groups join table
      self.projects = Hmis::Hud::Project.hmis.where(id: effective_project_ids)
    end

    def effective_project_ids
      included_project_ids = parsed_inclusion_criteria.effective_project_ids
      excluded_project_ids = parsed_exclusion_criteria.effective_project_ids
      included_project_ids - excluded_project_ids
    end

    def describe_criteria_as_html
      'TODO'
    end
  end
end
