###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Imports Coordinated Entry configuration. Runs after projects are imported.
    class CeImporter
      include Logging

      NODE_TYPES = ['StartEvent', 'EndEvent', 'UserTask', 'ScriptTask', 'Gateway'].map { |name| "Hmis::WorkflowDefinition::#{name}" }.freeze

      def initialize(ce_payload, data_source_id:, projects:, output:)
        @ce = ce_payload
        @data_source_id = data_source_id
        @projects = projects
        @output = output
        @unit_groups = {}
      end

      def run
        import_project_groups
        import_settings
        import_keyed(Hmis::Ce::CustomReferralStatus, 'referral_statuses', ['name', 'treatment'])
        import_keyed(Hmis::Ce::ReferralDeclineReason, 'decline_reasons', ['name'])
        import_templates
        import_unit_types
        import_unit_type_mappings
        import_unit_groups
        import_units
      end

      # Kept separate so it runs last: rules, unit groups, and CE project configs each rebuild
      # candidate pools when saved.
      def import_match_rules
        @ce.fetch('match_rules', []).each do |attrs|
          label = "match rule #{attrs['name']}"
          owner = find_rule_owner(attrs['owner'])
          next log("SKIP #{label}: owner #{attrs['owner']} not found locally") unless owner

          rule = Hmis::Ce::Match::Rule.find_or_initialize_by(owner: owner, name: attrs['name'])
          next log("SKIP #{label}: local rule_type #{rule.rule_type} differs and can't change") if rule.persisted? && rule.rule_type != attrs['rule_type']

          rank_holder = attrs['priority_rank'] && Hmis::Ce::Match::Rule.where(owner: owner, priority_rank: attrs['priority_rank']).where.not(id: rule.id).first
          next log("SKIP #{label}: priority_rank #{attrs['priority_rank']} is held by #{rank_holder.name}") if rank_holder

          rule.assign_attributes(attrs.slice('rule_type', 'applicability_config', 'expression', 'priority_rank'))
          log_save(rule, label)
        end
      end

      private

      def import_project_groups
        @ce.fetch('project_groups', []).each do |attrs|
          group = Hmis::ProjectGroup.find_or_initialize_by(data_source_id: @data_source_id, name: attrs['name'])
          group.assign_attributes(
            notes: attrs['notes'],
            inclusion_criteria: local_criteria(attrs['inclusion_criteria'], attrs['name']).to_json,
            exclusion_criteria: local_criteria(attrs['exclusion_criteria'], attrs['name']).to_json,
          )
          log_save(group, "project group #{attrs['name']}")
          group.maintain_projects!
        end
      end

      def local_criteria(criteria, group_name)
        criteria = criteria.dup
        project_hud_ids = Array.wrap(criteria.delete('project_hud_ids'))
        organization_hud_ids = Array.wrap(criteria.delete('organization_hud_ids'))
        criteria['project_ids'] = project_hud_ids.filter_map { |id| @projects.find_project(id)&.id&.to_s }
        criteria['organization_ids'] = organization_hud_ids.filter_map { |id| @projects.find_organization(id)&.id&.to_s }
        missing = (project_hud_ids.size - criteria['project_ids'].size) + (organization_hud_ids.size - criteria['organization_ids'].size)
        log("project group #{group_name}: #{missing} project(s) or organization(s) in its criteria not found locally") if missing.positive?
        criteria
      end

      def import_settings
        @ce.fetch('settings', []).each do |attrs|
          label = "setting #{attrs['key']}"
          value = attrs.key?('project_group_name') ? Hmis::ProjectGroup.find_by(data_source_id: @data_source_id, name: attrs['project_group_name'])&.id : attrs['value']
          # AppConfigProperty requires a present value, which also rules out false.
          next log("SKIP #{label}: no value to store") if value.blank?

          property = AppConfigProperty.find_or_initialize_by(key: attrs['key'])
          property.value = value
          log_save(property, label)
        end
      end

      def import_keyed(klass, payload_key, columns)
        @ce.fetch(payload_key, []).each do |attrs|
          record = klass.with_deleted.find_or_initialize_by(data_source_id: @data_source_id, key: attrs['key'])
          record.assign_attributes(attrs.slice(*columns).merge('deleted_at' => nil))
          log_save(record, "#{klass.name.demodulize} #{attrs['key']}")
        end
      end

      # Referrals point at a template's database id, so an existing (identifier, version) is never replaced.
      # Template versions are unique per identifier across data sources.
      def import_templates
        @ce.fetch('workflow_templates', []).each do |attrs|
          label = "workflow template #{attrs['identifier']} v#{attrs['version']} (#{attrs['status']})"
          templates = Hmis::WorkflowDefinition::Template.where(identifier: attrs['identifier'])
          existing = templates.with_deleted.find_by(version: attrs['version'])
          next log("SKIP #{label}: a soft-deleted local copy exists") if existing&.deleted_at
          next log(existing.data_source_id == @data_source_id ? "exists #{label}" : "SKIP #{label}: belongs to data source #{existing.data_source_id}") if existing
          next log("SKIP #{label}: a local #{attrs['status']} version already exists") if attrs['status'].in?(['draft', 'published']) && templates.where(status: attrs['status']).exists?

          Hmis::WorkflowDefinition::Template.transaction(requires_new: true) { create_template(attrs) }
          log("create #{label}")
        rescue ActiveRecord::RecordInvalid => e
          log("SKIP #{label}: #{e.record.class.name.demodulize} #{e.message}")
        end
      end

      def create_template(attrs)
        template = Hmis::WorkflowDefinition::Template.create!(
          **attrs.slice('identifier', 'name', 'version', 'status', 'template_type', 'description').symbolize_keys,
          data_source_id: @data_source_id,
        )
        swimlanes = attrs['swimlanes'].to_h { |name| [name, template.swimlanes.create!(name: name)] }
        nodes = attrs['nodes'].to_h do |node|
          raise "Unknown workflow node type #{node['type']}" unless node['type'].in?(NODE_TYPES)

          record = node['type'].constantize.create!(
            **node.slice('name', 'form_definition_identifier', 'gateway_type', 'trigger_config').symbolize_keys,
            template: template,
            swimlane_id: swimlanes[node['swimlane']]&.id,
          )
          [node['ref'], record]
        end
        attrs['flows'].each do |flow|
          Hmis::WorkflowDefinition::Flow.create!(
            **flow.slice('condition', 'position').symbolize_keys,
            template: template,
            source_node: nodes.fetch(flow['source_ref']),
            target_node: nodes.fetch(flow['target_ref']),
          )
        end
      end

      # Unit types are shared by every data source. Matched by description.
      def import_unit_types
        @ce.fetch('unit_types', []).each do |attrs|
          unit_type = Hmis::UnitType.find_or_initialize_by(description: attrs['description'])
          unit_type.assign_attributes(attrs.slice('bed_type', 'unit_size'))
          log_save(unit_type, "unit type #{attrs['description']}")
        end
      end

      def unit_type(description)
        Hmis::UnitType.find_by(description: description) if description
      end

      def import_unit_type_mappings
        @ce.fetch('project_unit_type_mappings', []).each do |attrs|
          project = @projects.find_project(attrs['project_hud_id'])
          next log("SKIP unit type mapping: project #{attrs['project_hud_id']} not found locally") unless project

          mapping = Hmis::ProjectUnitTypeMapping.find_or_initialize_by(project_id: project.id, unit_type: unit_type(attrs['unit_type']))
          mapping.assign_attributes(attrs.slice('unit_capacity', 'active'))
          log_save(mapping, "unit type mapping #{attrs['unit_type']} for #{project.ProjectID}")
        end
      end

      # Template identifiers and unit type can't change once set, so a differing local value is kept.
      def import_unit_groups
        @ce.fetch('unit_groups', []).each do |attrs|
          label = "unit group #{attrs['name']}"
          project = @projects.find_project(attrs['project_hud_id'])
          next log("SKIP #{label}: project #{attrs['project_hud_id']} not found locally") unless project

          # Name uniqueness includes soft-deleted groups, so a deleted match is restored.
          group = Hmis::UnitGroup.with_deleted.where(project_id: project.id).find_by(Hmis::UnitGroup.arel_table[:name].lower.eq(attrs['name'].downcase)) ||
            Hmis::UnitGroup.new(project_id: project.id)
          group.assign_attributes(**attrs.slice('name', 'ce_event_type').symbolize_keys, deleted_at: nil)
          {
            'workflow_template_identifier' => attrs['workflow_template_identifier'],
            'direct_referral_workflow_template_identifier' => attrs['direct_referral_workflow_template_identifier'],
            'unit_type_id' => unit_type(attrs['unit_type'])&.id,
          }.each do |column, value|
            if group[column].blank?
              group[column] = value
            elsif group[column] != value
              log("keeping local #{column} #{group[column].inspect} on #{label}; source has #{value.inspect}")
            end
          end
          next log("SKIP #{label}: #{group.errors.full_messages.join(', ')}") unless group.valid?

          log_save(group, "#{label} for #{project.ProjectID}")
          @unit_groups[[attrs['project_hud_id'], attrs['name'].downcase]] = group
        end
      end

      # Units often have no name, so they're counted rather than matched: for each distinct unit,
      # create however many the local project is missing. Extra local units are left alone.
      def import_units
        user_id = User.system_user.id
        @ce.fetch('units', []).group_by(&:itself).each do |attrs, copies|
          label = "#{copies.size} unit(s) #{attrs['name'] || '(unnamed)'} in #{attrs['unit_group'] || 'no group'}"
          project = @projects.find_project(attrs['project_hud_id'])
          next log("SKIP #{label}: project #{attrs['project_hud_id']} not found locally") unless project

          unit_group = attrs['unit_group'] ? @unit_groups[[attrs['project_hud_id'], attrs['unit_group'].downcase]] : nil
          next log("SKIP #{label}: unit group was not imported") if attrs['unit_group'] && !unit_group

          unit_attrs = {
            project_id: project.id,
            name: attrs['name'],
            unit_size: attrs['unit_size'],
            unit_type: unit_type(attrs['unit_type']),
            unit_group: unit_group,
          }
          ranges = attrs.fetch('active_ranges', [])
          existing = Hmis::Unit.where(unit_attrs).preload(:active_ranges).count { |unit| FormTransfer.active_range_signature(unit) == ranges }
          missing = copies.size - existing
          next log("unchanged #{label} for #{project.ProjectID}") unless missing.positive?

          missing.times do
            unit = Hmis::Unit.create!(**unit_attrs, user_id: user_id)
            ranges.each { |range| unit.active_ranges.create!(**range.symbolize_keys, user_id: user_id.to_s) }
          end
          log("create #{missing} of #{label} for #{project.ProjectID}")
        end
      end

      def find_rule_owner(ref)
        case ref['type']
        when GrdaWarehouse::DataSource.sti_name then GrdaWarehouse::DataSource.find(@data_source_id)
        when Hmis::Hud::Project.sti_name then @projects.find_project(ref['project_hud_id'])
        when Hmis::Hud::Organization.sti_name then @projects.find_organization(ref['organization_hud_id'])
        when Hmis::UnitGroup.sti_name then @unit_groups[[ref['project_hud_id'], ref['name'].downcase]]
        end
      end
    end
  end
end
