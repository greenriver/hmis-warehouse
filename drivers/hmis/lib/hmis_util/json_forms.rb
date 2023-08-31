###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class JsonForms
    DATA_DIR = 'drivers/hmis/lib/form_data'.freeze

    protected

    def fragment_map
      @fragment_map ||= begin
        fragments = {}
        Dir.glob("#{DATA_DIR}/default/fragments/*.json") do |file_path|
          identifier = File.basename(file_path, '.json')
          file = File.read(file_path)
          fragments[identifier] = JSON.parse(file)
        end

        # If we're in a client env, override any fragments
        if ENV['CLIENT'].present?
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/fragments/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            puts "Loading #{ENV['CLIENT']} override for #{identifier} fragment"
            file = File.read(file_path)
            fragments[identifier] = JSON.parse(file)
          end
        end
        fragments
      end
    end

    def record_forms
      @record_forms ||= begin
        forms = {}
        Dir.glob("#{DATA_DIR}/default/records/*.json") do |file_path|
          identifier = File.basename(file_path, '.json')
          file = File.read(file_path)
          forms[identifier] = JSON.parse(file)
        end

        if ENV['CLIENT'].present?
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/records/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            # puts "Applying #{ENV['CLIENT']} override for #{identifier} form"
            file = File.read(file_path)
            forms[identifier] = JSON.parse(file)
          end
        end
        forms
      end
    end

    def client_override(file_path)
      return file_path unless ENV['CLIENT'].present?

      client_override_fpath = file_path.gsub('/default/', "/#{ENV['CLIENT']}/")
      if File.exist?(client_override_fpath)
        client_override_fpath
      else
        file_path
      end
    end

    # { ROLE => { identifier => definition }}
    def record_forms_by_role
      @record_forms_by_role ||= begin
        forms = {}

        # Load system forms. File name = role. Apply client override file if present.
        Dir.glob("#{DATA_DIR}/default/records/*.json") do |file_path|
          identifier = File.basename(file_path, '.json')
          role = identifier.upcase.to_sym
          raise "Unrecognized record form: #{identifier}" unless Hmis::Form::Definition::FORM_ROLES.key?(role)

          file_path = client_override(file_path)
          # puts "Loading #{identifier} from #{file_path}"
          file = File.read(file_path)
          forms[role] ||= {}
          forms[role][identifier] = JSON.parse(file)
        end

        # Load non-system forms
        [
          [:services, :SERVICE],
          [:occurrence_point_forms, :OCCURRENCE_POINT],
        ].each do |dirname, role|
          forms[role] ||= {}
          # Load defaults
          Dir.glob("#{DATA_DIR}/default/#{dirname}/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            # puts "Loading #{identifier} from #{file_path}"
            file = File.read(file_path)
            forms[role][identifier] = JSON.parse(file)
          end
          next unless ENV['CLIENT'].present?

          # Load client-specific
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/#{dirname}/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            file_path = client_override(file_path)
            # puts "Loading #{identifier} from #{file_path}"
            file = File.read(file_path)
            forms[role][identifier] = JSON.parse(file)
          end
        end
        forms
      end
    end

    def apply_patches(tree, patches)
      nodes_by_id = {}
      result = tree.deep_dup
      walk_nodes(result) do |node|
        id = node['link_id']
        nodes_by_id[id] = node
      end
      applied_patches = []
      patches.each do |patch|
        id = patch.fetch('link_id')
        node = nodes_by_id[id]
        next unless node.present? # ok to skip, just means that this form doesn't contain this link id

        applied_patches << id
        children, patch_to_apply = patch.partition { |k, _| ['append_items', 'prepend_items'].include?(k) }.map(&:to_h)
        # Could also be deep merge. This is probably more intuitive though
        node.merge!(patch_to_apply)

        # Prepend or append any child items
        raise 'Cannot append/prepend to item with no children' if children.any? && node['item'].nil?

        node['item'].unshift(*children['prepend_items']) if children['prepend_items'].present?
        node['item'].push(*children['append_items']) if children['append_items'].present?
      end
      [result, applied_patches]
    end

    def apply_all_patches!(definition, identifier:)
      applied_patches = []
      Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/fragments/patches/*.json") do |file_path|
        # patch_name = File.basename(file_path, '.json')
        file = File.read(file_path)
        definition['item'].each do |item|
          result, applied = apply_patches(item, JSON.parse(file))
          item.replace(result)
          applied_patches.push(*applied)
        end
      end
      puts "Patches applied to #{identifier}: #{applied_patches.compact.uniq.join(', ')}" if applied_patches.any?
    end

    def walk_nodes(node, &block)
      block.call(node)
      children = node['item']
      children&.each { |child| walk_nodes(child, &block) }
    end

    def resolve_fragment!(item, safety: 0)
      raise 'Safety count exceeded' if safety > 5
      return unless item['fragment'].present?

      fragment_key = item['fragment']&.gsub(/^#/, '')
      fragment = fragment_map[fragment_key]
      raise "Fragment not found #{item['fragment']}" unless fragment.present?

      fragment_items = fragment['item'] || [] # child items of the fragment
      additional_items = item['item'] || [] # any items that should be appended

      # Reverse merge so that any keys specified in 'item' overried the fragment values.
      # This can be useful in changing the link id, text, etc.
      # This is a shallow merge.
      item.reverse_merge!(fragment)
      # If this item was adding any additional items, we need to add the fragment items
      # since they wouldn't have been copied by the shallow merge
      item['item'].unshift(*fragment_items) if additional_items.any? && fragment_items.any?

      # Remove the fragment field
      item.delete('fragment')

      return unless fragment['fragment'].present?

      # If the fragment ALSO had a fragment key on it, resolve that.
      item['fragment'] = fragment['fragment']
      resolve_fragment!(item, safety: safety + 1)
    end

    def resolve_all_fragments!(definition)
      walk_nodes(definition) do |item|
        resolve_fragment!(item)
      end
    end

    # This function creates/updates a FormDefinition, and applies any fragments and patches.
    #
    # FRAGMENTS are for re-using questions across forms.
    # PATCHES are for applying installation-specific changes to any item in the form.
    #
    # First, we resolve any fragments that are referenced throughout the form.
    # Next, we apply any installation-specific patches, which could make
    # any arbitrary changes to any item (by Link ID), including inserting additional items.
    #
    # This approach lets you do something like change the link_id for a fragment (by specifying
    # a different link_id on the assessment),
    # and then apply a patch just to that link id. A use-case would be if you
    # want to change something about Disability fragment just for Intake,
    # not other assessments.
    def load_definition(form_definition:, identifier:, role:, title: nil)
      raise "Invalid role: #{role}" unless Hmis::Form::Definition::FORM_ROLES.key?(role.to_sym)

      # Resolve all fragments, so we have a full definition
      resolve_all_fragments!(form_definition)
      # Apply any client-specific patches
      apply_all_patches!(form_definition, identifier: identifier)
      # Validate final definition
      validate_definition(form_definition, role)

      # Create or update definition
      record = Hmis::Form::Definition.where(
        identifier: identifier,
        role: role,
        version: 0,
        status: 'draft',
      ).first_or_create!
      record.definition = form_definition
      record.title ||= title
      record.save!
    end

    public def ensure_system_instances_exist!
      [
        :project,
        :organization,
        :project_coc,
        :funder,
        :inventory,
        :client,
        :new_client_enrollment,
        :enrollment,
      ].each do |identifier|
        role = identifier.upcase.to_sym
        raise "Unrecognized record form: #{identifier}" unless Hmis::Form::Definition::FORM_ROLES.key?(role)

        default_instance = Hmis::Form::Instance.defaults.where(definition_identifier: identifier).first_or_create!
        default_instance.update(system: true, active: true)
        default_instance.touch
      end
    end

    # Create some default HUD occurrence point instances
    public def create_default_occurrence_point_instances!
      # Move-in Date
      unless Hmis::Form::Instance.where(definition_identifier: 'move_in_date').exists?
        [3, 9, 10, 13].each do |ptype|
          Hmis::Form::Instance.create!(
            definition_identifier: 'move_in_date',
            project_type: ptype,
            data_collected_about: :HOH,
            active: true,
            system: false,
          )
        end
      end

      # Date of Engagement
      unless Hmis::Form::Instance.where(definition_identifier: 'date_of_engagement').exists?
        # Note: spec has funder components too, but by default we just show it for all 3 project types.
        [1, 4, 6].each do |ptype|
          Hmis::Form::Instance.create!(
            definition_identifier: 'date_of_engagement',
            project_type: ptype,
            data_collected_about: :HOH_AND_ADULTS,
            active: true,
            system: false,
          )
        end
      end

      # PATH Status
      return if Hmis::Form::Instance.where(definition_identifier: 'path_status').exists?

      Hmis::Form::Instance.create!(
        definition_identifier: 'path_status',
        funder: 21,
        data_collected_about: :HOH_AND_ADULTS,
        active: true,
        system: false,
      )
    end

    FORM_TITLES = {
      'move_in_date' => 'Move-in Date',
      'date_of_engagement' => 'Date of Engagement',
      'path_status' => 'PATH Status',
    }.freeze

    # Load form definitions for editing and creating records
    public def seed_record_form_definitions
      record_forms_by_role.each do |role, definition_hash|
        definition_hash.each do |identifier, form_definition|
          # puts "#{identifier} => #{role}"
          load_definition(
            form_definition: form_definition,
            identifier: identifier,
            role: role,
            title: FORM_TITLES[identifier] || identifier.humanize,
          )
        end
      end
      ensure_system_instances_exist!
      # puts "Saved definitions with identifiers: #{record_forms.keys.join(', ')}"
    end

    # Load form definitions for HUD assessments
    public def seed_assessment_form_definitions
      roles = [:INTAKE, :EXIT, :UPDATE, :ANNUAL]
      identifiers = []
      roles.each do |role|
        filename = "base_#{role.to_s.downcase}.json"
        begin
          file = File.read("#{DATA_DIR}/#{ENV['CLIENT']}/assessments/#{filename}")
        rescue Errno::ENOENT
          nil # no client override, which is fine
        end
        file ||= File.read("#{DATA_DIR}/default/assessments/#{filename}")
        form_definition = JSON.parse(file)

        # Load definition into database
        identifier = "base-#{role.to_s.downcase}"
        identifiers << identifier

        load_definition(
          form_definition: form_definition,
          identifier: identifier,
          role: role,
        )

        # Make this form the default instance for this role
        default_instance = Hmis::Form::Instance.defaults.where(definition_identifier: identifier).first_or_create!
        default_instance.update(system: true, active: true)
        default_instance.touch
      end
      # puts "Saved definitions with identifiers: #{identifiers.join(', ')}"
    end

    def validate_definition(json, role)
      Hmis::Form::Definition.validate_json(json, valid_pick_lists: valid_pick_lists)
      schema_errors = Hmis::Form::Definition.validate_schema(json)
      return unless schema_errors.present?

      pp schema_errors
      raise "schema invalid for role: #{role}"
    end

    def valid_pick_lists
      @valid_pick_lists ||= begin
        pick_list_references = []
        pick_list_references << all_enums_in_schema(Types::HmisSchema::QueryType)
        pick_list_references << all_enums_in_schema(Types::HmisSchema::MutationType)
        pick_list_references << Types::Forms::Enums::PickListType.values.keys
        pick_list_references.flatten.uniq.sort
      end
    end

    # Traverse schema to find ALL enums used
    def all_enums_in_schema(schema, traversed_types: [])
      enums = []
      schema.fields.each do |_, field|
        type = field.type
        (type = type&.of_type) while type.non_null? || type.list?
        seen = traversed_types.include?(type)
        traversed_types << type
        if type.respond_to?(:fields) && type.to_s.include?('::HmisSchema::') && !seen
          enums << all_enums_in_schema(type, traversed_types: traversed_types)
        elsif type.to_s.include?('::Enums::')
          enums << type.graphql_name
        # Hacky way to traverse into paginated node, because its an anonymous class
        elsif type.to_s&.ends_with?('Paginated') && !type.to_s.include?('AuditEvent')
          node_type = "Types::HmisSchema::#{type.to_s.gsub('Paginated', '').singularize}".constantize
          seen_node_type = traversed_types.include?(node_type)
          traversed_types << node_type
          enums << all_enums_in_schema(node_type, traversed_types: traversed_types) unless seen_node_type
        end
      end
      return enums.flatten.sort.uniq
    end
  end
end
