###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class JsonForms
    JsonFormException = Class.new(StandardError)
    private_constant :JsonFormException

    DATA_DIR = 'drivers/hmis/lib/form_data'.freeze

    def self.seed_all
      new.seed_all
    end

    def seed_all
      # Load ALL the latest record definitions from JSON files.
      # This also ensures that any system-level instances exist.
      seed_record_form_definitions
      # Load ALL the latest assessment definition from JSON files.
      seed_assessment_form_definitions
      seed_custom_assessment_form_definitions
      # Load admin forms (not configurable)
      seed_static_forms
    end

    protected

    def env_key
      @env_key ||= if Rails.env.test?
        'test'
      elsif ENV['CLIENT'].present?
        ENV['CLIENT']
      elsif Rails.env.development?
        # default to QA environment in development to get forms with all possible questions enabled
        'qa_hmis'
      end
    end

    def fragment_map
      @fragment_map ||= begin
        fragments = {}
        Dir.glob("#{DATA_DIR}/default/fragments/*.json") do |file_path|
          identifier = File.basename(file_path, '.json')
          file = File.read(file_path)
          fragments[identifier] = JSON.parse(file)
        end

        # If we're in a client env, override any fragments
        if env_key
          Dir.glob("#{DATA_DIR}/#{env_key}/fragments/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            puts "Loading #{env_key} override for #{identifier} fragment"
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

        if env_key
          Dir.glob("#{DATA_DIR}/#{env_key}/records/*.json") do |file_path|
            identifier = File.basename(file_path, '.json')
            # puts "Applying #{env_key} override for #{identifier} form"
            file = File.read(file_path)
            forms[identifier] = JSON.parse(file)
          end
        end
        forms
      end
    end

    def client_override(file_path)
      return file_path unless env_key

      client_override_fpath = file_path.gsub('/default/', "/#{env_key}/")
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
          raise "Unrecognized record form: #{identifier}" unless Hmis::Form::Definition::FORM_ROLES.include?(role)

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
          next unless env_key.present?

          # Load client-specific
          Dir.glob("#{DATA_DIR}/#{env_key}/#{dirname}/*.json") do |file_path|
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

        # if patch replaces references with options, remove the reference to avoid schema violation
        node.delete('pick_list_reference') if patch_to_apply.key?('pick_list_options')
        # Could also be deep merge. This is probably more intuitive though
        node.merge!(patch_to_apply).compact!

        # Prepend or append any child items
        raise 'Cannot append/prepend to item with no children' if children.any? && node['item'].nil?

        node['item'].unshift(*children['prepend_items']) if children['prepend_items'].present?
        node['item'].push(*children['append_items']) if children['append_items'].present?
      end
      [result, applied_patches]
    end

    def apply_all_patches!(definition, identifier:)
      applied_patches = []
      Dir.glob("#{DATA_DIR}/#{env_key}/fragments/patches/*.json") do |file_path|
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
      raise "Invalid role: #{role}" unless Hmis::Form::Definition::FORM_ROLES.include?(role.to_sym)

      # Resolve all fragments, so we have a full definition
      resolve_all_fragments!(form_definition)

      # Apply any client-specific patches
      apply_all_patches!(form_definition, identifier: identifier)

      # Create or update definition
      record = Hmis::Form::Definition.where(
        identifier: identifier,
        role: role,
        version: 0,
      ).first_or_initialize(title: title || role.to_s.humanize)
      record.definition = form_definition
      record.title = title if title.present?
      record.status = Hmis::Form::Definition::PUBLISHED

      # Ensure HUD rules are set
      # changed = record.set_hud_requirements
      # raise "hud rules wrong for #{identifier}" if changed

      # Validate final definition
      begin
        validate_definition(record.definition, record.role)
      rescue JsonFormException => e
        # If there was an error, _try_ to print out the exact value that failed by traversing the json path
        match_path = /property '(.*)'/.match(e.to_s)
        if match_path&.size == 2
          dig_path = match_path[1].split('/').map(&:presence).compact.map { |s| Integer(s, exception: false) || s }
          problem_item = record.definition.dig(*dig_path)
        end
        raise "Failed to validate #{role}/#{identifier} (item##{problem_item || 'unknown'}): #{e}"
      end

      record.save!
    end

    public def ensure_system_instances_exist!
      Hmis::Form::Definition::SYSTEM_FORM_ROLES.each do |role|
        identifier = role.to_s.downcase
        raise "No definition found for role: #{role}" unless Hmis::Form::Definition.where(identifier: identifier).exists?

        default_instance = Hmis::Form::Instance.defaults.where(definition_identifier: identifier).first_or_create!
        default_instance.update(system: true, active: true)
        default_instance.touch
      end
    end

    # Create some default HUD occurrence point instances
    public def create_default_occurrence_point_instances!
      # Move-in Date
      unless Hmis::Form::Instance.where(definition_identifier: 'move_in_date').exists?
        HudUtility2024.permanent_housing_project_types.each do |ptype|
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
        # Note: spec has funder components too, but by default we just show it for the project types.
        HudUtility2024.doe_project_types.each do |ptype|
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

      HudUtility2024.path_funders.each do |funder|
        Hmis::Form::Instance.create!(
          definition_identifier: 'path_status',
          funder: funder,
          data_collected_about: :HOH_AND_ADULTS,
          active: true,
          system: false,
        )
      end
    end

    FORM_TITLES = {
      'move_in_date' => 'Move-in Date',
      'date_of_engagement' => 'Date of Engagement',
      'path_status' => 'PATH Status',
      'base-intake' => 'Intake Assessment',
      'base-exit' => 'Exit Assessment',
      'base-post_exit' => 'Post Exit Assessment',
      'base-update' => 'Update Assessment',
      'base-annual' => 'Annual Assessment',
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
            title: FORM_TITLES[identifier],
          )
        end
      end
      ensure_system_instances_exist!
      # puts "Saved definitions with identifiers: #{record_forms.keys.join(', ')}"
    end

    # Load form definitions for HUD assessments
    public def seed_assessment_form_definitions
      roles = [:INTAKE, :EXIT, :UPDATE, :ANNUAL, :POST_EXIT]
      identifiers = []
      roles.each do |role|
        filename = "base_#{role.to_s.downcase}.json"
        begin
          file = File.read("#{DATA_DIR}/#{env_key}/assessments/#{filename}")
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
          title: FORM_TITLES[identifier],
        )

        # Don't create default instance for post-exit. Those are going to be configured per installation
        next if role == :POST_EXIT

        # Make this form the default instance for this role
        default_instance = Hmis::Form::Instance.defaults.where(definition_identifier: identifier).first_or_create!
        default_instance.update(system: true, active: true)
        default_instance.touch
      end
      # puts "Saved definitions with identifiers: #{identifiers.join(', ')}"
    end

    def seed_custom_assessment_form_definitions
      dirname = "#{DATA_DIR}/#{env_key}/custom_assessments"
      return unless Dir.exist?(dirname)

      Dir.glob("#{dirname}/*").each do |filename|
        raise 'nested directories not supported' if File.directory?(filename)

        # use file filename as identifier
        identifier = File.basename(filename, File.extname(filename))
        hud_identifiers = [:INTAKE, :EXIT, :UPDATE, :ANNUAL].map { |role| "base-#{role.to_s.downcase}" }
        raise "custom assessment name \"#{file_name}\" overlaps with HUD assessment" if identifier.in?(hud_identifiers)

        load_definition(
          form_definition: parse_json_file(filename),
          identifier: identifier,
          role: :CUSTOM_ASSESSMENT,
          title: identifier.humanize,
        )
      end
    end

    def parse_json_file(filename)
      JSON.parse(File.read(filename))
    end

    public def seed_static_forms
      Hmis::Form::Definition::STATIC_FORM_ROLES.each do |role|
        filename = "#{DATA_DIR}/static/#{role.to_s.downcase}.json"
        next unless File.exist?(filename) # skip deprecated roles

        file = File.read(filename)
        form_definition = JSON.parse(file)
        load_definition(
          form_definition: form_definition,
          identifier: role.to_s.downcase,
          role: role,
          title: role.to_s.titlecase,
        )
      end
    end

    # on_error allows customization of error handling incase we want to collect them instead of raising
    # TODO make this not public anymore. it is only used by some one-time-migrations. OK to make private now?
    public def validate_definition(json, role = nil)
      issues = Hmis::Form::DefinitionValidator.perform(json, role)
      raise(JsonFormException, issues.first.full_message) if issues.any?
    end
  end
end
