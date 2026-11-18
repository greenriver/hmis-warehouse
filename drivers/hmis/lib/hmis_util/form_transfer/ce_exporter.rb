###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Coordinated Entry configuration. Runtime data (candidate pools, opportunities, referrals,
    # workflow executions) is left out; candidate pools rebuild from the imported rules and unit groups.
    class CeExporter
      ELIGIBILITY_GROUP_KEY = 'hmis_ce/eligibility_project_group_id'

      def initialize(data_source_id:, refs:)
        @data_source_id = data_source_id
        @refs = refs
      end

      def build
        {
          settings: settings,
          project_groups: project_groups,
          referral_statuses: Hmis::Ce::CustomReferralStatus.where(data_source_id: @data_source_id).order(:key).map { |s| s.slice(:key, :name, :treatment) },
          decline_reasons: Hmis::Ce::ReferralDeclineReason.where(data_source_id: @data_source_id).order(:key).map { |r| r.slice(:key, :name) },
          workflow_templates: Hmis::WorkflowDefinition::Template.where(data_source_id: @data_source_id).order(:identifier, :version).map { |t| export_template(t) },
          unit_types: Hmis::UnitType.order(:id).map { |t| t.slice(:description, :bed_type, :unit_size) },
          project_unit_type_mappings: Hmis::ProjectUnitTypeMapping.where(project_id: project_scope).preload(:unit_type).order(:id).map { |m| export_mapping(m) },
          unit_groups: Hmis::UnitGroup.where(project_id: project_scope).preload(:unit_type).order(:id).map { |g| export_unit_group(g) },
          units: Hmis::Unit.where(project_id: project_scope).preload(:unit_type, :unit_group, :active_ranges).order(:id).map { |u| export_unit(u) },
          match_rules: Hmis::Ce::Match::Rule.preload(:owner).order(:id).filter_map { |r| export_rule(r) },
        }
      end

      # Forms the workflow templates' steps use. Templates can't be imported without them.
      def form_identifiers
        Hmis::WorkflowDefinition::Node.
          where(template_id: Hmis::WorkflowDefinition::Template.where(data_source_id: @data_source_id).select(:id)).
          where.not(form_definition_identifier: nil).
          distinct.
          pluck(:form_definition_identifier)
      end

      private

      def project_scope
        Hmis::Hud::Project.where(data_source_id: @data_source_id).select(:id)
      end

      def eligibility_group
        return @eligibility_group if defined?(@eligibility_group)

        id = AppConfigProperty.find_by(key: ELIGIBILITY_GROUP_KEY)&.value
        @eligibility_group = id.present? ? Hmis::ProjectGroup.find_by(id: id, data_source_id: @data_source_id) : nil
      end

      # CE settings are global. The eligibility group is written by name because its id differs between installations.
      def settings
        AppConfigProperty.where(AppConfigProperty.arel_table[:key].matches('hmis_ce/%')).order(:key).map do |property|
          next { key: property.key, project_group_name: eligibility_group&.name } if property.key == ELIGIBILITY_GROUP_KEY

          { key: property.key, value: property.value }
        end
      end

      def project_groups
        group = eligibility_group
        return [] unless group

        [
          {
            name: group.name,
            notes: group.notes,
            inclusion_criteria: export_criteria(group.inclusion_criteria, group),
            exclusion_criteria: export_criteria(group.exclusion_criteria, group),
          },
        ]
      end

      # Criteria hold project and organization database ids.
      def export_criteria(json, group)
        criteria = JSON.parse(json || '{}')
        context = "project group #{group.name}"
        criteria['project_hud_ids'] = Array.wrap(criteria.delete('project_ids')).filter_map { |id| @refs.project_hud_id(id, context: context) }
        criteria['organization_hud_ids'] = Array.wrap(criteria.delete('organization_ids')).filter_map { |id| @refs.organization_hud_id(id, context: context) }
        criteria
      end

      # Nodes and flows point at each other by database id, so each node gets a ref the flows use instead.
      def export_template(template)
        @refs.warnings << "workflow template #{template.identifier} v#{template.version} has an owner (#{template.owner_type}); the owner is not exported" if template.owner_type
        swimlanes = template.swimlanes.to_h { |swimlane| [swimlane.id, swimlane.name] }
        {
          **template.slice(:identifier, :name, :version, :status, :template_type, :description),
          swimlanes: swimlanes.values,
          nodes: Hmis::WorkflowDefinition::Node.where(template_id: template.id).order(:id).map do |node|
            { ref: node.id, swimlane: swimlanes[node.swimlane_id], **node.slice(:type, :name, :form_definition_identifier, :gateway_type, :trigger_config) }
          end,
          flows: Hmis::WorkflowDefinition::Flow.where(template_id: template.id).order(:id).map do |flow|
            { source_ref: flow.source_node_id, target_ref: flow.target_node_id, **flow.slice(:condition, :position) }
          end,
        }
      end

      def export_mapping(mapping)
        {
          project_hud_id: @refs.project_hud_id(mapping.project_id, context: "unit type mapping #{mapping.id}"),
          unit_type: mapping.unit_type&.description,
          **mapping.slice(:unit_capacity, :active),
        }
      end

      def export_unit_group(group)
        {
          project_hud_id: @refs.project_hud_id(group.project_id, context: "unit group #{group.name}"),
          unit_type: group.unit_type&.description,
          **group.slice(:name, :workflow_template_identifier, :direct_referral_workflow_template_identifier, :ce_event_type),
        }
      end

      def export_unit(unit)
        {
          project_hud_id: @refs.project_hud_id(unit.project_id, context: "unit #{unit.id}"),
          unit_type: unit.unit_type&.description,
          unit_group: unit.unit_group&.name,
          **unit.slice(:name, :unit_size),
          active_ranges: FormTransfer.active_range_signature(unit),
        }
      end

      def export_rule(rule)
        owner = rule_owner_ref(rule)
        return unless owner

        { owner: owner, **rule.slice(:name, :rule_type, :applicability_config, :expression, :priority_rank) }
      end

      # nil when the owner is deleted or in another data source
      def rule_owner_ref(rule)
        owner = rule.owner
        context = "match rule #{rule.name}"
        case owner
        when GrdaWarehouse::DataSource
          { type: rule.owner_type } if owner.id == @data_source_id
        when Hmis::Hud::Project
          { type: rule.owner_type, project_hud_id: @refs.project_hud_id(owner.id, context: context) } if owner.data_source_id == @data_source_id
        when Hmis::Hud::Organization
          { type: rule.owner_type, organization_hud_id: @refs.organization_hud_id(owner.id, context: context) } if owner.data_source_id == @data_source_id
        when Hmis::UnitGroup
          { type: rule.owner_type, project_hud_id: @refs.project_hud_id(owner.project_id, context: context), name: owner.name } if owner.project&.data_source_id == @data_source_id
        end
      end
    end
  end
end
