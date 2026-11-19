###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Imports service types, file tags, form definitions, CDEDs, and form rules.
    class FormImporter
      include Logging

      def initialize(payload, data_source_id:, user_id:, output:)
        @payload = payload
        @data_source_id = data_source_id
        @user_id = user_id
        @output = output
        @service_types = {}
      end

      def import_forms
        import_service_types
        import_file_tags
        import_definitions
        import_cdeds
      end

      # Runs after projects are imported, since rules point at them.
      def import_rules(projects:)
        @payload.fetch('form_rules', []).each do |attrs|
          label = "rule #{attrs['definition_identifier']} -> #{attrs['entity_name'] || attrs['project_type'] || attrs['funder'] || 'all'}"
          entity = find_entity(attrs, projects)
          if attrs['entity_type'] && !entity
            log("SKIP #{label}: no local #{attrs['entity_type']} for HUD ID #{attrs['project_hud_id'] || attrs['organization_hud_id']}")
            next
          end

          rule = Hmis::Form::Instance.active.find_or_initialize_by(
            **attrs.slice('definition_identifier', 'funder', 'project_type', 'other_funder', 'data_collected_about').symbolize_keys,
            data_source_id: @data_source_id,
            entity: entity,
            custom_service_type: attrs['service_type'] ? find_service_type(attrs['service_type']) : nil,
            custom_service_category: find_category(attrs['service_category_name']),
          )
          next log("exists #{label}") if rule.persisted?

          log_save(rule, label)
        end
      end

      private

      def import_service_types
        # Rules can reference a category with no exported service type, so categories come first.
        @payload.fetch('service_categories', []).each { |category| find_category(category['name'], create: true) }
        @payload.fetch('service_types', []).each do |ref|
          service_type = find_service_type(ref) || build_service_type(ref)
          service_type.supports_bulk_assignment = ref['supports_bulk_assignment']
          log_save(service_type, "service type #{ref['name']}")
        end
      end

      def find_service_type(ref)
        @service_types[ref.slice('name', 'category_name', 'hud_record_type', 'hud_type_provided')] ||= begin
          scope = Hmis::Hud::CustomServiceType.where(data_source_id: @data_source_id)
          if ref['hud_record_type']
            scope.find_by(hud_record_type: ref['hud_record_type'], hud_type_provided: ref['hud_type_provided'])
          else
            scope.find_by(name: ref['name'], custom_service_category: find_category(ref['category_name']))
          end
        end
      end

      def build_service_type(ref)
        raise "HUD service type #{ref['name']} (#{ref['hud_record_type']}/#{ref['hud_type_provided']}) is missing locally; run HMIS seeds first" if ref['hud_record_type']

        Hmis::Hud::CustomServiceType.new(
          name: ref['name'],
          custom_service_category: find_category(ref['category_name'], create: true),
          data_source_id: @data_source_id,
          UserID: @user_id,
        )
      end

      def find_category(name, create: false)
        return unless name

        scope = Hmis::Hud::CustomServiceCategory.where(data_source_id: @data_source_id, name: name)
        create ? scope.first_or_create!(UserID: @user_id) : scope.first
      end

      # File tags are shared by every data source. Matched by name.
      def import_file_tags
        @payload.fetch('file_tags', []).each do |attrs|
          tag = GrdaWarehouse::AvailableFileTag.find_or_initialize_by(name: attrs['name'])
          tag.assign_attributes(attrs.slice(*FormTransfer.file_tag_columns))
          log_save(tag, "file tag #{attrs['name']}")
        end
      end

      def import_definitions
        @payload.fetch('definitions', []).group_by { |d| d['identifier'] }.each do |identifier, versions|
          local = Hmis::Form::Definition.where(data_source_id: @data_source_id, identifier: identifier)
          make_room(local, versions.to_h { |d| [d['version'], d['status']] })

          versions.each do |attrs|
            definition = local.find_or_initialize_by(version: attrs['version'])
            definition.assign_attributes(attrs.slice(*FormExporter::DEFINITION_COLUMNS).except('identifier', 'version'))
            log_save(definition, "definition #{identifier} v#{attrs['version']} (#{attrs['status']})")
          end
        end
      end

      # The unique indexes allow one published and one draft per identifier.
      # incoming_statuses maps each version in the file to its status.
      def make_room(local, incoming_statuses)
        local.published.each do |definition|
          next if incoming_statuses[definition.version] == Hmis::Form::Definition::PUBLISHED
          next unless incoming_statuses.key?(definition.version) || incoming_statuses.value?(Hmis::Form::Definition::PUBLISHED)

          log("retiring local #{definition.identifier} v#{definition.version} so the imported published version can take its place")
          definition.update!(status: Hmis::Form::Definition::RETIRED)
        end

        local.draft.each do |definition|
          next if incoming_statuses[definition.version] == Hmis::Form::Definition::DRAFT

          # Retired, not soft-deleted: the import then overwrites this row instead of adding a second one at the same version.
          if incoming_statuses.key?(definition.version)
            definition.update!(status: Hmis::Form::Definition::RETIRED)
          elsif incoming_statuses.value?(Hmis::Form::Definition::DRAFT)
            log("soft-deleting local draft #{definition.identifier} v#{definition.version} (id #{definition.id})")
            definition.destroy!
          end
        end
      end

      # (owner_type, key) is unique across data sources, so a key held by another data source can't be imported.
      def import_cdeds
        @payload.fetch('custom_data_element_definitions', []).each do |attrs|
          label = "CDED #{attrs['owner_type']}/#{attrs['key']}"
          cded = Hmis::Hud::CustomDataElementDefinition.with_deleted.find_or_initialize_by(owner_type: attrs['owner_type'], key: attrs['key'])
          if cded.data_source_id.present? && cded.data_source_id != @data_source_id
            log("SKIP #{label}: key belongs to data source #{cded.data_source_id}")
            next
          end

          cded.assign_attributes(
            **attrs.slice('field_type', 'label', 'repeats', 'show_in_summary', 'form_definition_identifier').symbolize_keys,
            data_source_id: @data_source_id,
            DateDeleted: nil,
          )
          cded.user_id ||= @user_id
          cded.reporting_key = available_reporting_key(cded, attrs['reporting_key'])
          log_save(cded, label)
        end
      end

      def available_reporting_key(cded, reporting_key)
        return reporting_key if reporting_key.blank?
        return reporting_key unless reporting_key_taken?(cded, reporting_key)

        current = cded.reporting_key_was
        return current if current.present? && !reporting_key_taken?(cded, current)

        replacement = Hmis::Form::CustomDataElementGenerator.generate_reporting_key(reporting_key, owner_type: cded.owner_type)
        log("reporting_key #{reporting_key} is taken locally; using #{replacement} for #{cded.key}")
        replacement
      end

      def reporting_key_taken?(cded, reporting_key)
        Hmis::Hud::CustomDataElementDefinition.
          where(owner_type: cded.owner_type, reporting_key: reporting_key).
          where.not(id: cded.id).
          exists?
      end

      def find_entity(attrs, projects)
        case attrs['entity_type']
        when Hmis::Hud::Project.sti_name then projects.find_project(attrs['project_hud_id'])
        when Hmis::Hud::Organization.sti_name then projects.find_organization(attrs['organization_hud_id'])
        end
      end
    end
  end
end
