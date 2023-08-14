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
            puts "Applying #{ENV['CLIENT']} override for #{identifier} form"
            file = File.read(file_path)
            forms[identifier] = JSON.parse(file)
          end
        end
        forms
      end
    end

    def service_forms
      @service_forms ||= begin
        forms = {}
        if ENV['CLIENT'].present?
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/services/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            file = File.read(file_path)
            forms[identifier] = JSON.parse(file)
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
    def load_definition(form_definition:, identifier:, role:)
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
      record.save!
    end

    # Load form definitions for editing and creating records
    public def seed_record_form_definitions
      record_forms.merge(service_forms).each do |identifier, form_definition|
        role = identifier.upcase.to_sym
        role = :SERVICE if service_forms.key?(identifier)
        raise "Unrecognized record form: #{identifier}" unless Hmis::Form::Definition::FORM_ROLES.key?(role)

        load_definition(
          form_definition: form_definition,
          identifier: identifier,
          role: role,
        )

        # Make this form the default instance  for this role. Don't do it for service forms since those
        # need specialized instances based on service type.
        unless service_forms.key?(identifier)
          instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil, definition_identifier: identifier)
          instance.save!
        end
      end

      puts "Saved definitions with identifiers: #{record_forms.keys.join(', ')}"
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
        instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil, definition_identifier: identifier)
        instance.save!
      end
      puts "Saved definitions with identifiers: #{identifiers.join(', ')}"
    end

    def validate_definition(json, role)
      Hmis::Form::Definition.validate_json(json)
      schema_errors = Hmis::Form::Definition.validate_schema(json)
      return unless schema_errors.present?

      pp schema_errors
      raise "schema invalid for role: #{role}"
    end
  end
end
