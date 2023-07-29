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
        node.merge!(patch)
      end
      result
    end

    def walk_nodes(node, &block)
      block.call(node)
      children = node['item']
      children&.each { |child| walk_nodes(child, &block) }
    end

    def apply_fragment(item)
      return item unless item['fragment']

      additional_children = item['item']
      fragment_key = item['fragment']&.gsub(/^#/, '')
      fragment = fragment_map[fragment_key]
      raise "Fragment not found #{item['fragment']}" unless fragment.present?

      merged = { **item.except('fragment'), **fragment }
      # Add custom fields to the end
      merged['item'] = (merged['item'] || []) + (additional_children || [])
      merged
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

        form_definition['item'] = form_definition['item'].map { |item| apply_fragment(item) }
        # Validate form structure
        Hmis::Form::Definition.validate_json(form_definition)
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

      form_definition['item'] = form_definition['item'].map { |item| apply_fragment(item) }
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
        file = File.read("#{DATA_DIR}/default/assessments/base_#{role.to_s.downcase}.json")
        next unless file.present?

        # Replace fragment references in JSON
        form_definition = JSON.parse(file)
        form_definition['item'] = form_definition['item'].map { |item| apply_fragment(item) }

        # Validate form structure
        Hmis::Form::Definition.validate_json(form_definition)
        schema_errors = Hmis::Form::Definition.validate_schema(form_definition)
        if schema_errors.present?
          pp schema_errors
          raise "schema invalid for role: #{role}"
        end

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
  end
end
