###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class JsonForms
    JsonFormException = Class.new(StandardError)
    private_constant :JsonFormException

    DATA_DIR = 'drivers/hmis/lib/form_data'

    def initialize(env_key: nil, enable_cded_generation_in_test: false)
      @env_key = env_key if env_key.presence # allow override for testing
      @enable_cded_generation_in_test = enable_cded_generation_in_test # normally in test, CDEDs are not generated, but some tests override that behavior
    end

    def self.seed_all
      new.seed_all
    end

    def seed_all
      Hmis::Hud::Base.transaction do
        # Load the latest record definitions from JSON files. (Client, Project, Enrollment, etc.)
        # and ensure that required system-level instances exist.
        seed_record_form_definitions
        # Load the latest assessment definitions from JSON files. (Intake, Exit, Update, Annual, Post-exit)
        seed_assessment_form_definitions
        # Load custom assessment definitions from JSON files. (Only for testing/QA, typically custom assessments are not managed in version control)
        seed_custom_assessment_form_definitions
        # Load static admin forms
        seed_static_forms
      end
    end

    protected

    def enable_cded_generation_in_test?
      @enable_cded_generation_in_test
    end

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
          [:ce_referral_steps, :CE_REFERRAL_STEP],
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

    # Apply applicable patches to the "tree" which is a top-level item in the form definition.
    # The patches passed may not apply to this tree. They are only applied if the `link_id` matches
    # an item in the tree.
    # Patches can override item attributes (such as "text") or append/prepend items to Group items.
    def apply_item_patches(tree, patches)
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

    # Similar to apply_item_patches, but applies patches to the overall form
    # instead of to an individual item. This was added to support appending an item
    # to the Service form.
    def apply_form_patches(definition, patches, identifier:)
      result = definition.deep_dup
      applied_patches = []
      patches.filter { |patch| patch['form_identifier'] == identifier && !patch.key?('link_id') }.each do |patch|
        result['item'].unshift(*patch['prepend_items']) if patch['prepend_items'].present?
        result['item'].push(*patch['append_items']) if patch['append_items'].present?
        applied_patches << patch['form_identifier']
      end
      [result, applied_patches]
    end

    def apply_all_patches!(definition, identifier:)
      applied_patches = []
      Dir.glob("#{DATA_DIR}/#{env_key}/fragments/patches/*.json") do |file_path|
        file = File.read(file_path)
        patches = JSON.parse(file)
        # Split patches into "item patches" and "form patches"
        item_patches, form_patches = patches.partition { |h| h.key?('link_id') }

        # Apply form-level patches (appending and prepending items to system forms)
        result, applied = apply_form_patches(definition, form_patches, identifier: identifier)
        definition.replace(result)
        applied_patches.push(*applied)

        # Apply item-level patches (overriding item attributes, and appending/prepending items to groups)
        definition['item'].each do |item|
          result, applied = apply_item_patches(item, item_patches)
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

      data_source = GrdaWarehouse::DataSource.hmis.order(:id).first # TODO(#6612, #6691): specify data source for seeding. for now choose first.

      # Find or initialize the definition record
      record = Hmis::Form::Definition.where(
        identifier: identifier,
        role: role,
        version: 0,
      ).first_or_initialize(title: title || identifier.to_s.humanize)
      record.managed_in_version_control = true
      record.definition = form_definition
      record.title = title if title.present?
      record.status = Hmis::Form::Definition::PUBLISHED

      # Ensure HUD rules are set
      record.set_hud_requirements

      # Generate and validate CDEDs if this isn't a test env, OR if it is a test env but enable_cded_generation_in_test flag is true.
      should_generate_cdeds = !Rails.env.test? || enable_cded_generation_in_test?

      if should_generate_cdeds
        # Create/update CDEDs for items that have { mapping: { custom_field_key: '...' } }
        cdeds = Hmis::Form::CustomDataElementGenerator.new(
          definition: record,
          create_missing_mappings: false,
          data_source: data_source,
          set_form_definition_identifier: !record.hud_assessment?, # don't set for custom fields on HUD assessments because they are often repeated across data collection stages
        ).run
        cdeds.each(&:save!)
      end

      # Validate definition
      # puts "Validating FormDefinition: \"#{record.identifier}\" ##{record.id}"
      errors = Hmis::Form::DefinitionValidator.perform(
        form_definition,
        role,
        skip_cded_validation: !should_generate_cdeds, # skip validation if we didn't generate CDEDs
      )
      raise(JsonFormException, errors.first.full_message) if errors.any?

      record.save!
    end

    # Ensure necessary system instances exist for HUD compliance. System instances cannot be removed in the admin UI.
    public def ensure_system_instances_exist!
      # Ensure form rules exist to enable all System Forms globally
      Hmis::Form::Definition::SYSTEM_FORM_ROLES.each do |role|
        create_default_system_instance!(identifier: role.to_s.downcase)
      end

      # Find or create required rules for HUD Occurrence Point forms (Move-in Date, Date of Engagement, and Path Status)
      create_system_instances!(
        identifier: 'move_in_date',
        data_collected_about: :HOH,
        project_types: HudHelper.util.permanent_housing_project_types,
        funders: HudHelper.util.move_in_date_funders,
      )
      create_system_instances!(
        identifier: 'date_of_engagement',
        data_collected_about: :HOH_AND_ADULTS,
        project_types: HudHelper.util.doe_project_types,
      )
      create_system_instances!(
        identifier: 'path_status',
        data_collected_about: :HOH_AND_ADULTS,
        funders: HudHelper.util.path_funders,
      )

      # Enforce system rules for the default Current Living Situation form (HUD-required collection).
      # These rules are very specific (funder-level) and intentionally match exactly what HUD requires.
      # For CLS it is common for customers to expand collection at the project type level (e.g. all shelters,
      # all street outreach); adding such rules is fine since they only expand collection. Customers must not
      # be able to delete these system rules, or the system would fall out of HUD compliance.
      HudHelper.util.current_living_situation_funder_applicability_requirements.each do |spec|
        create_system_instance!(
          identifier: 'current_living_situation',
          data_collected_about: :HOH_AND_ADULTS,
          project_type: spec[:project_type],
          funder: spec[:funder],
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
    public def seed_record_form_definitions(roles: [])
      added_identifiers = []
      record_forms_by_role.each do |role, definition_hash|
        next if roles.any? && !roles.map(&:to_s).include?(role.to_s)

        definition_hash.each do |identifier, form_definition|
          # puts "Loading #{identifier} => #{role}"
          added_identifiers << identifier
          load_definition(
            form_definition: form_definition,
            identifier: identifier,
            role: role,
            title: FORM_TITLES[identifier],
          )
        end
      end
      # Ensure system instances exist for records, so the application functions correctly and HUD compliance is met.
      ensure_system_instances_exist! unless Rails.env.test?
      # puts "Saved definitions with identifiers: #{added_identifiers.join(', ')}"
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

        if role == :POST_EXIT
          # Ensure minimum rule exists for Post-exit which is required for RHY
          create_system_instances!(
            identifier: identifier,
            data_collected_about: :HOH_AND_ADULTS,
            funders: HudHelper.util.post_exit_aftercare_plans_funders,
          )
        else
          # Ensure default rule exists for other HUD assessments (enabled in all projects)
          create_default_system_instance!(identifier: identifier)
        end
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

    # Create or update system instances for the given identifier. System instances are used to ensure HUD-required forms are properly enabled,
    # and cannot be deleted in the interface. At least one of project_types or funders must be provided.
    # When both are given: creates one rule per project_type (funder: nil) and one rule per funder (project_type: nil), not every combination.
    private def create_system_instances!(identifier:, data_collected_about:, project_types: [], funders: [])
      raise 'must specify either project_types or funders' if project_types.empty? && funders.empty?

      project_types.each do |project_type|
        create_system_instance!(identifier: identifier, data_collected_about: data_collected_about, project_type: project_type, funder: nil)
      end
      funders.each do |funder|
        create_system_instance!(identifier: identifier, data_collected_about: data_collected_about, project_type: nil, funder: funder)
      end
    end

    # Create or update a single system instance for the given identifier. At least one of project_type or funder must be provided.
    # If project_type and funder are both specified, the rule will apply to projects that match both the project type and funder.
    private def create_system_instance!(identifier:, data_collected_about:, project_type: nil, funder: nil)
      raise 'must specify project_type and/or funder' if project_type.blank? && funder.blank?
      raise "form not found: #{identifier}" unless Hmis::Form::Definition.published.managed_in_version_control.where(identifier: identifier).exists?

      instance = Hmis::Form::Instance.find_or_initialize_by(
        definition_identifier: identifier,
        data_collected_about: data_collected_about,
        project_type: project_type,
        funder: funder,
        entity: nil,
      )
      instance.assign_attributes(active: true, system: true)
      instance.save! if instance.changed?
    end

    # Find or create default system instance, which applies to all projects
    private def create_default_system_instance!(identifier:)
      instance = Hmis::Form::Instance.defaults.find_or_initialize_by(definition_identifier: identifier)
      instance.assign_attributes(active: true, system: true)
      instance.save! if instance.changed?
    end
  end
end
