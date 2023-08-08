###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class JsonForms
    DATA_DIR = 'drivers/hmis/lib/form_data'.freeze

    protected

    # Fragments are for re-using questions across different assessments.
    # Patches are for applying installation-specific changes to those patches.
    #
    # Note: patches don't necessarily need to be tied to fragments, maybe
    # we should decouple them so patches can be organized however.
    #
    # Another thought: instead of doing it this way, resolve all the fragments
    # on the assessment FIRST, then apply the patches. That would let you
    # do something like change the link id for a fragment (at resolution time)
    # and then apply a patch just to that version. A use-case would be if you
    # want to change something about Disability fragment just for Intake,
    # not other assessments.
    def fragment_map
      @fragment_map ||= begin
        fragments = {}
        Dir.glob("#{DATA_DIR}/default/fragments/*.json") do |file_path|
          identifier = File.basename(file_path, '.json')
          file = File.read(file_path)
          fragments[identifier] = JSON.parse(file)
        end

        if ENV['CLIENT'].present?
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/fragments/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            puts "Loading #{ENV['CLIENT']} override for #{identifier} fragment"
            file = File.read(file_path)
            fragments[identifier] = JSON.parse(file)
          end
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/fragments/patches/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            puts "Applying #{ENV['CLIENT']} patch for #{identifier} fragment"
            file = File.read(file_path)
            fragment = fragments.fetch(identifier)
            fragments[identifier] = apply_patches(fragment, JSON.parse(file))
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

    def apply_patches(tree, patches)
      nodes_by_id = {}
      result = tree.deep_dup
      walk_nodes(result) do |node|
        id = node['link_id']
        nodes_by_id[id] = node
      end
      patches.each do |patch|
        id = patch.fetch('link_id')
        node = nodes_by_id.fetch(id)

        children, patch_to_apply = patch.partition { |k, _| ['append_items', 'prepend_items'].include?(k) }.map(&:to_h)
        # Could also be deep merge. This is probably more intuitive though
        node.merge!(patch_to_apply)

        # Prepend or append any child items
        raise 'Cannot append/prepend to item with no children' if children.any? && node['item'].nil?

        node['item'].unshift(*children['prepend_items']) if children['prepend_items'].present?
        node['item'].push(*children['append_items']) if children['append_items'].present?
      end
      result
    end

    def walk_nodes(node, &block)
      block.call(node)
      children = node['item']
      children&.each { |child| walk_nodes(child, &block) }
    end

    def apply_fragment(base_item)
      walk_nodes(base_item) do |item|
        next unless item['fragment'].present?

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
      end
    end

    # Load form definitions for editing and creating records
    public def seed_record_form_definitions
      record_forms.each do |identifier, form_definition|
        role = identifier.upcase.to_sym
        next unless Hmis::Form::Definition::FORM_ROLES.key?(role)

        definition = Hmis::Form::Definition.find_or_create_by(
          identifier: identifier,
          version: 0,
          role: role,
          status: 'draft',
        )

        form_definition['item'].each { |i| apply_fragment(i) }

        # Validate form structure
        validate_definition(form_definition, role)
        definition.definition = form_definition
        definition.save!

        # Make this form the default instance for this role
        instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil, definition_identifier: identifier)
        instance.save!
      end

      puts "Saved definitions with identifiers: #{record_forms.keys.join(', ')}"
    end

    public def load_definition(identifier, role:)
      form_definition = record_forms[identifier.to_s]
      raise "Not found: #{identifier}" unless form_definition.present?
      raise "Invalid role: #{role}" unless Hmis::Form::Definition::FORM_ROLES.key?(role.to_sym)

      # Apply fragments and patches
      form_definition['item'].each { |i| apply_fragment(i) }

      Hmis::Form::Definition.validate_json(form_definition)
      record = Hmis::Form::Definition.where(
        identifier: identifier,
        role: role,
        version: 0,
        status: 'draft',
      ).first_or_create!
      record.definition = form_definition
      record.save!
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

        # Replace fragment references in JSON
        form_definition = JSON.parse(file)
        form_definition['item'].each { |i| apply_fragment(i) }

        # Validate form structure
        validate_definition(form_definition, role)

        # Load definition into database
        identifier = "base-#{role.to_s.downcase}"
        identifiers << identifier
        definition = Hmis::Form::Definition.find_or_create_by(
          identifier: identifier,
          version: 0,
          role: role,
          status: 'draft',
        )
        definition.definition = form_definition
        definition.save!

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
