###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Organizations and projects that form rules, project configs, or CE configuration point at, with
    # each project's funders, ProjectCoCs, and inventory. An organization form rule brings every
    # project in the organization, since the rule applies to all of them.
    class ProjectExporter
      def initialize(rules:, extra_project_ids:, refs:, data_source_id:)
        @rules = rules
        @extra_project_ids = extra_project_ids
        @refs = refs
        @data_source_id = data_source_id
      end

      def build
        entities = @rules.map(&:entity).compact
        rule_organizations = entities.grep(Hmis::Hud::Organization)
        projects = entities.grep(Hmis::Hud::Project) +
          rule_organizations.flat_map(&:projects) +
          Hmis::Hud::Project.where(data_source_id: @data_source_id, ProjectID: @extra_project_ids).to_a +
          Hmis::Hud::Project.where(data_source_id: @data_source_id, id: @refs.project_ids.to_a).to_a
        projects = projects.uniq(&:id).sort_by(&:ProjectID).select do |project|
          next true if project.organization

          @refs.warnings << "project #{project.ProjectID} belongs to a missing or deleted organization"
          false
        end
        organizations = rule_organizations + projects.map(&:organization) +
          Hmis::Hud::Organization.where(data_source_id: @data_source_id, id: @refs.organization_ids.to_a).to_a

        {
          organizations: organizations.compact.uniq(&:id).sort_by(&:OrganizationID).map { |organization| HudColumns.slice(organization) },
          projects: projects.map { |project| export_project(project) },
        }
      end

      private

      def export_project(project)
        children = HudColumns::PROJECT_CHILDREN.keys.to_h do |association|
          [association, project.public_send(association).map { |child| HudColumns.slice(child) }]
        end
        HudColumns.slice(project).merge(children)
      end
    end
  end
end
