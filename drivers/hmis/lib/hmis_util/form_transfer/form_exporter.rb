###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Form definitions, their CDEDs and form rules, and the pick list data that isn't tied to projects.
    class FormExporter
      DEFINITION_COLUMNS = [
        'identifier', 'version', 'role', 'status', 'title', 'definition',
        'external_form_object_key', 'managed_in_version_control', 'admin_editable_only'
      ].freeze

      attr_reader :rules, :warnings

      # @param required_identifiers [Array<String>] exported even when identifiers or roles leave them out
      def initialize(data_source_id:, identifiers:, roles:, required_identifiers: [])
        @data_source_id = data_source_id
        @identifiers = identifiers
        @roles = roles
        @required_identifiers = required_identifiers
        @warnings = []
        @rules = []
      end

      def build
        definitions = definition_scope.order(:identifier, :version).to_a
        raise 'No form definitions matched' if definitions.empty?

        @rules = rules_for(definitions.map(&:identifier).uniq)
        {
          definitions: definitions.map { |definition| export_definition(definition) },
          custom_data_element_definitions: cdeds_for(definitions).map { |cded| export_cded(cded) },
          form_rules: @rules.map { |rule| export_rule(rule) },
          service_categories: Hmis::Hud::CustomServiceCategory.where(data_source_id: @data_source_id).order(:id).map { |c| { name: c.name } },
          service_types: service_types.map { |service_type| export_service_type(service_type) },
          file_tags: GrdaWarehouse::AvailableFileTag.order(:id).map { |tag| tag.slice(*FormTransfer.file_tag_columns) },
          pick_list_references: pick_list_references(definitions),
        }
      end

      private

      def definition_scope
        all = Hmis::Form::Definition.where(data_source_id: @data_source_id)
        return all if @identifiers.empty? && @roles.empty?

        scope = all
        scope = scope.where(identifier: @identifiers) if @identifiers.any?
        scope = scope.where(role: @roles) if @roles.any?
        scope.or(all.where(identifier: @required_identifiers))
      end

      # Older CDEDs may have no form_definition_identifier, so the forms' field mappings are walked too.
      def cdeds_for(definitions)
        scope = Hmis::Hud::CustomDataElementDefinition.where(data_source_id: @data_source_id)
        found = scope.where(form_definition_identifier: definitions.map(&:identifier).uniq).to_a

        definitions.each do |definition|
          definition.link_id_item_hash.each_value do |item|
            key = item.dig('mapping', 'custom_field_key')
            next unless key

            owner_type = FormTransfer.cded_owner_type(item, definition)
            cded = scope.find_by(key: key, owner_type: owner_type)
            if cded
              found << cded
            else
              @warnings << "#{definition.identifier} v#{definition.version} item #{item['link_id']} maps to missing CDED #{owner_type}/#{key}"
            end
          end
        end
        found.uniq(&:id).sort_by { |cded| [cded.owner_type, cded.key] }
      end

      def rules_for(identifiers)
        rules = Hmis::Form::Instance.active.not_system.
          where(data_source_id: @data_source_id, definition_identifier: identifiers).
          preload(:entity, :custom_service_type, :custom_service_category).
          order(:definition_identifier, :id).
          to_a
        rules.select { |rule| rule.entity_type && !rule.entity }.each do |rule|
          @warnings << "rule #{rule.id} for #{rule.definition_identifier} points at a missing #{rule.entity_type} (#{rule.entity_id})"
        end
        rules
      end

      # All custom service types, not just the ones rules use, so the ALL_SERVICE_TYPES pick list matches the source.
      def service_types
        Hmis::Hud::CustomServiceType.where(data_source_id: @data_source_id, hud_record_type: nil).
          or(Hmis::Hud::CustomServiceType.where(id: @rules.map(&:custom_service_type_id))).
          preload(:custom_service_category).
          order(:id)
      end

      def export_definition(definition)
        definition.slice(*DEFINITION_COLUMNS)
      end

      def export_cded(cded)
        cded.slice(:owner_type, :key, :field_type, :label, :repeats, :show_in_summary, :form_definition_identifier, :reporting_key)
      end

      def export_rule(rule)
        entity = rule.entity
        {
          **rule.slice(:definition_identifier, :funder, :project_type, :other_funder, :data_collected_about),
          entity_type: rule.entity_type,
          project_hud_id: entity.is_a?(Hmis::Hud::Project) ? entity.project_id : nil,
          organization_hud_id: entity.is_a?(Hmis::Hud::Organization) ? entity.organization_id : nil,
          entity_name: entity.try(:name),
          service_type: rule.custom_service_type ? service_type_ref(rule.custom_service_type) : nil,
          service_category_name: rule.custom_service_category&.name,
        }
      end

      def export_service_type(service_type)
        { **service_type_ref(service_type), supports_bulk_assignment: service_type.supports_bulk_assignment }
      end

      def service_type_ref(service_type)
        {
          name: service_type.name,
          category_name: service_type.category&.name,
          hud_record_type: service_type.hud_record_type,
          hud_type_provided: service_type.hud_type_provided,
        }
      end

      # Server-side pick lists read local data, so they can't be exported; this lists them for review.
      def pick_list_references(definitions)
        definitions.group_by(&:identifier).transform_values do |versions|
          versions.flat_map { |definition| definition.link_id_item_hash.values.filter_map { |item| item['pick_list_reference'] } }.uniq.sort
        end.select { |_, references| references.any? }
      end
    end
  end
end
