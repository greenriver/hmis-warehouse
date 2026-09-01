###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class HudDataCollectionGapAnalyzer
    # Builds the list of scannable HUD data elements from the *unpatched* default form
    # definitions, so results reflect true HUD minimums rather than whatever patches a
    # given installation happens to have seeded.
    #
    # This parses the JSON directly instead of using HmisUtil::JsonForms because JsonForms
    # has no public entry point that skips environment overrides: its loading internals are
    # protected, its env_key cannot be forced off, and its constructor requires an HMIS data
    # source (which an imported warehouse-only data source is not).
    class ElementRegistry
      DATA_DIR = 'drivers/hmis/lib/form_data/default'
      ASSESSMENT_ROLES = [:INTAKE, :EXIT, :UPDATE, :ANNUAL, :POST_EXIT].freeze

      RECORD_TYPE_ASSOCIATIONS = {
        'INCOME_BENEFIT' => :income_benefits,
        'DISABILITY_GROUP' => :disabilities,
        'HEALTH_AND_DV' => :health_and_dvs,
        'EMPLOYMENT_EDUCATION' => :employment_educations,
        'YOUTH_EDUCATION_STATUS' => :youth_education_statuses,
      }.freeze

      # DISPLAY items are labels; they store no value.
      SKIPPED_ITEM_TYPES = ['DISPLAY'].freeze

      MAX_FRAGMENT_DEPTH = 5

      # @return [Array<Element>]
      def assessment_elements
        @assessment_elements ||= ASSESSMENT_ROLES.flat_map { |role| elements_for_role(role) }
      end

      # The fragment-resolved, HUD-rule-annotated definition for a role.
      #
      # Returns a fresh deep copy every call: Hmis::Form::DefinitionItemFilter rewrites
      # item['item'] in place, so a shared tree would be progressively emptied as projects
      # are filtered, and every project after the first would see a truncated form.
      #
      # @param role [Symbol]
      # @return [Hash]
      def definition_tree(role)
        load_definition(role).deep_dup
      end

      protected

      def elements_for_role(role)
        elements = []
        walk_nodes(load_definition(role)) do |item|
          element = build_element(role, item)
          elements << element if element
        end
        elements
      end

      def build_element(role, item)
        mapping = item['mapping']
        return nil unless mapping

        record_type = mapping['record_type']
        return nil unless RECORD_TYPE_ASSOCIATIONS.key?(record_type)

        item_type = item['type']
        return nil if item_type.in?(SKIPPED_ITEM_TYPES)

        field_name = mapping['field_name']
        return nil if field_name.blank?

        Element.new(
          role: role,
          link_id: item['link_id'],
          record_type: record_type,
          field_name: field_name,
          item_type: item_type,
        )
      end

      def load_definition(role)
        definitions[role] ||= build_definition(role)
      end

      def definitions
        @definitions ||= {}
      end

      def build_definition(role)
        definition = JSON.parse(File.read("#{DATA_DIR}/assessments/base_#{role.to_s.downcase}.json"))
        walk_nodes(definition) { |item| resolve_fragment!(item) }
        apply_hud_rules!(definition, role)
        # Some HUD_LINK_ID_RULES entries are written with symbol keys, and eval_rule looks
        # them up as strings. In production the definition round-trips through the database
        # as JSON, which stringifies them; an in-memory tree has to do it explicitly or
        # eval_rule raises KeyError: key not found: "parts".
        JSON.parse(definition.to_json)
      end

      # Mirrors the rule half of Hmis::Form::Definition#set_hud_requirements: HUD rules are
      # not stored in the JSON, they are written onto matching link ids at seed time. Rules
      # key on group link ids, and DefinitionItemFilter drops a failing group's descendants.
      #
      # Those group link ids sit on nodes the base assessment file owns. Nodes reached
      # through a fragment are shared with every other role referencing that fragment,
      # because resolve_fragment! merges the fragment's child array by reference, so a rule
      # keyed on one of them would be written once and then read by all five roles.
      def apply_hud_rules!(definition, role)
        walk_nodes(definition) do |item|
          # hud_data_element_rule calls link_id.to_sym; container nodes often have none.
          next if item['link_id'].blank?

          rule = rule_module.hud_data_element_rule(role, item['link_id'])
          item['rule'] = rule if rule
        end
      end

      # NB: instance methods, not class methods -- matches definition.rb:630.
      def rule_module
        @rule_module ||= HmisUtil::HudAssessmentFormRules2026.new
      end

      # Mirrors HmisUtil::JsonForms#walk_nodes: visit the node, then its children. Resolving a
      # fragment on the way down makes that fragment's children available to the recursion.
      def walk_nodes(node, &block)
        block.call(node)
        node['item']&.each { |child| walk_nodes(child, &block) }
      end

      # Mirrors HmisUtil::JsonForms#resolve_fragment!, minus environment overrides.
      def resolve_fragment!(item, depth: 0)
        raise "Fragment nesting exceeded #{MAX_FRAGMENT_DEPTH} levels" if depth > MAX_FRAGMENT_DEPTH
        return if item['fragment'].blank?

        fragment_key = item['fragment'].sub(/\A#/, '')
        fragment = fragment_map[fragment_key]
        raise "Fragment not found: #{item['fragment']}" if fragment.blank?

        fragment_items = fragment['item'] || []
        additional_items = item['item'] || []

        item.reverse_merge!(fragment)
        item['item'].unshift(*fragment_items) if additional_items.any? && fragment_items.any?
        item.delete('fragment')

        return if fragment['fragment'].blank?

        item['fragment'] = fragment['fragment']
        resolve_fragment!(item, depth: depth + 1)
      end

      def fragment_map
        @fragment_map ||= Dir.glob("#{DATA_DIR}/fragments/*.json").index_by do |path|
          File.basename(path, '.json')
        end.transform_values { |path| JSON.parse(File.read(path)) }
      end
    end
  end
end
