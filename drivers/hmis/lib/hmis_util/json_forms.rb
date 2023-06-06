###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class JsonForms
    DATA_DIR = 'drivers/hmis/lib/form_data'.freeze

    def self.fragment_map
      @@fragment_map ||= begin # rubocop:disable Style/ClassVars
        fragments = {}
        Dir.glob("#{DATA_DIR}/default/fragments/*.json") do |file_path|
          identifier = File.basename(file_path, '.json')
          file = File.read(file_path)
          fragments["##{identifier}"] = JSON.parse(file)
        end

        if ENV['CLIENT'].present?
          Dir.glob("#{DATA_DIR}/#{ENV['CLIENT']}/fragments/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            puts "Loading #{ENV['CLIENT']} override for #{identifier} fragment"
            file = File.read(file_path)
            fragments["##{identifier}"] = JSON.parse(file)
          end
        end

        fragments
      end
    end

    def self.record_forms
      @@record_forms ||= begin # rubocop:disable Style/ClassVars
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

    def self.apply_fragment(item)
      return item unless item['fragment']

      additional_children = item['item']
      fragment = fragment_map[item['fragment']]
      raise "Fragment not found #{item['fragment']}" unless fragment.present?

      merged = { **item.except('fragment'), **fragment }
      # Add custom fields to the end
      merged['item'] = (merged['item'] || []) + (additional_children || [])
      merged
    end

    # Load form definitions for editing and creating records
    def self.seed_record_form_definitions
      # role_map = { service_custom: :SERVICE }.freeze
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
        definition.definition = form_definition.to_json
        definition.save!

        # Make this form the default instance for this role
        instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil, definition_identifier: identifier)
        instance.save!
      end

      puts "Saved definitions with identifiers: #{record_forms.keys.join(', ')}"
    end

    # Load form definitions for HUD assessments
    def self.seed_assessment_form_definitions
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

        # Load definition into database
        identifier = "base-#{role.to_s.downcase}"
        identifiers << identifier
        definition = Hmis::Form::Definition.find_or_create_by(
          identifier: identifier,
          version: 0,
          role: role,
          status: 'draft',
        )
        definition.definition = form_definition.to_json
        definition.save!

        # Make this form the default instance for this role
        instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil, definition_identifier: identifier)
        instance.save!
      end
      puts "Saved definitions with identifiers: #{identifiers.join(', ')}"
    end
  end
end
