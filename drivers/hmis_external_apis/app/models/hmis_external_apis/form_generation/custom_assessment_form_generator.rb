###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'json'
require 'yaml'

# Builds Custom Assessment form-definition JSON from a CSV of custom
# assessment field rows. Expected columns: form_definition_identifier,
# legacy_assessment_name, form_group_name, form_item_link_id (or link_id),
# label, key, form_item_type, pick_list_options.
#
# That is the form-builder export shape from the HMIS-migration custom
# assessment fields dbt model. Invoke via
# `rails driver:hmis_external_apis:generate_custom_assessment_forms` so
# Rails (and ::Hmis::Form::DefinitionValidator) are loaded.
#
# overlay_path is a YAML sidecar (invented group titles, enable_when,
# item_order, hidden). It is loaded first and applied to this run's JSON.
# After generation the file is rewritten: your keys win over inferred
# ones, new form identifiers are appended, and stale keys are not removed.
module HmisExternalApis
  module FormGeneration
    class CustomAssessmentFormGenerator
      ASSESSMENT_DATE_LINK_ID = 'assessment_date'
      ALLOWED_TYPES = ['STRING', 'TEXT', 'DATE', 'INTEGER', 'CURRENCY', 'CHOICE'].freeze
      # "12. text", "8. a) text", "4. b) text". Does not match "1c. If Other" (letter glued to the number).
      NUMBERED_LABEL = /\A\s*(\d+)\s*[.)]\s*(?:([a-zA-Z])\s*[.)])?/
      START_DATE_LABEL = /\A\s*start date\b/i
      PRE_SURVEY_LABEL = /\A\s*PRE[- ]?SURVEY\b/i
      LETTERED_SECTION_LABEL = /\A\s*([A-Z])\.\s+\S/i
      NUMBERED_UNIQUE_RATIO = 0.9
      OTHER_LABEL = /if other|please specify|please describe/i
      IF_YES_LABEL = /if yes/i
      MULTISELECT_LABEL = /all that apply|select all|check all/i
      DO_NOT_USE_LABEL = /\bdo not use\b|\bdisregard\b|\Aignore\b/i
      SUBASSESSMENT_NAME = /subassess/i

      Warning = Struct.new(:kind, :identifier, :title, :link_id, :label, :detail, keyword_init: true)

      def self.call(...) = new(...).call

      def initialize(csv_path:, output_dir:, overlay_path:, zip: false)
        @csv_path = csv_path.to_s
        @output_dir = output_dir.to_s
        @overlay_path = overlay_path.to_s
        @zip = zip
        @warnings = []
        @validator_errors = []
        @form_titles = {}
        @skipped_rows = 0
      end

      def call
        overlay = load_overlay
        generated_overlay = { 'forms' => {} }
        rows_by_form = read_csv

        FileUtils.mkdir_p(@output_dir)
        Dir.glob(File.join(@output_dir, '*.json')).each { |path| FileUtils.rm_f(path) }

        rows_by_form.each do |identifier, rows|
          form_overlay = overlay.dig('forms', identifier) || {}
          document, form_generated = build_form(identifier, rows, form_overlay)
          generated_overlay['forms'][identifier] = form_generated

          path = File.join(@output_dir, "#{identifier}.json")
          File.write(path, "#{JSON.pretty_generate(document)}\n")

          validate_form(identifier, document)
        end

        write_overlay(merge_overlay(overlay, generated_overlay))
        zip_path = write_zip if @zip
        print_summary(rows_by_form.keys.size, zip_path)

        {
          warnings: @warnings,
          validator_errors: @validator_errors,
          success: @validator_errors.empty?,
          zip_path: zip_path,
        }
      end

      private

      def read_csv
        grouped = {}
        CSV.foreach(@csv_path, headers: true, encoding: 'bom|utf-8') do |row|
          identifier = row['form_definition_identifier']&.strip
          if identifier.blank?
            @skipped_rows += 1
            next
          end

          grouped[identifier] ||= []
          @form_titles[identifier] ||= row['legacy_assessment_name'].to_s.strip
          grouped[identifier] << {
            # Form Definition identifier
            'identifier' => identifier,
            # Assessment title shown as the form name
            'legacy_assessment_name' => row['legacy_assessment_name'].to_s.strip,
            # Section title; blank rows are ungrouped
            'form_group_name' => row['form_group_name'].to_s.strip.presence,
            # Item link_id for the question
            'link_id' => (row['link_id'].presence || row['form_item_link_id'].presence).to_s.strip,
            # Question text
            'label' => row['label'].to_s,
            # CustomDataElementDefinition key (mapping.custom_field_key)
            'key' => row['key'].to_s.strip,
            # Form item type (STRING, CHOICE, DATE, …)
            'form_item_type' => row['form_item_type'].to_s.strip,
            # Pipe-delimited CHOICE codes (pick_list_options)
            'pick_list_options' => row['pick_list_options'].to_s,
          }
        end
        grouped
      end

      def build_form(identifier, rows, form_overlay)
        title = rows.first['legacy_assessment_name']
        used_link_ids = Set.new(rows.map { |r| r['link_id'] })
        runs = group_runs(rows, title, form_overlay)
        form_generated = {
          'invented_group_names' => {},
          'flattened_subassessments' => [],
          'enable_when' => {},
        }

        groups = runs.map do |run|
          form_generated['invented_group_names'][run[:invented_key]] = run[:text] if run[:invented_key]
          if run[:source_name].to_s.match?(SUBASSESSMENT_NAME)
            form_generated['flattened_subassessments'] << run[:source_name]
            @warnings << Warning.new(
              kind: :flattened_subassessment,
              identifier: identifier,
              title: title,
              link_id: nil,
              label: run[:source_name],
              detail: 'flattened to a regular group',
            )
          end
          if run[:invented_key] && !run[:from_overlay]
            @warnings << Warning.new(
              kind: :invented_group,
              identifier: identifier,
              title: title,
              link_id: run[:link_id],
              label: run[:text],
              detail: run[:invented_key],
            )
          end

          ordered = order_rows(run[:rows], group_name: run[:text], form_overlay: form_overlay)
          items = build_items(identifier, ordered, form_overlay, form_generated)
          {
            'type' => 'GROUP',
            'link_id' => unique_link_id(slug(run[:text]), used_link_ids),
            'text' => run[:text],
            'item' => items,
          }
        end

        if groups.empty?
          groups << {
            'type' => 'GROUP',
            'link_id' => unique_link_id(slug(title), used_link_ids),
            'text' => title,
            'item' => [],
          }
        end

        if groups.size > 1
          groups.unshift(details_group(used_link_ids))
        else
          groups.first['item'].unshift(assessment_date_item(used_link_ids))
        end

        document = {
          'name' => title,
          'item' => groups,
        }
        [document, form_generated]
      end

      def group_runs(rows, title, form_overlay)
        runs = []
        rows.each do |row|
          name = row['form_group_name']
          if runs.last && runs.last[:source_name] == name
            runs.last[:rows] << row
          else
            runs << { source_name: name, rows: [row] }
          end
        end

        ungrouped = runs.select { |run| run[:source_name].nil? }
        runs.each do |run|
          if run[:source_name]
            run[:text] = run[:source_name]
            next
          end

          idx = ungrouped.index(run)
          invented_key = "section_#{idx}"
          default_text = if runs.size == 1
            title
          elsif idx.zero?
            'Additional Questions'
          else
            "Additional Questions #{idx + 1}"
          end
          overlay_name = form_overlay.dig('invented_group_names', invented_key)
          run[:text] = overlay_name.presence || default_text
          run[:invented_key] = invented_key
        end
        runs
      end

      def order_rows(rows, group_name:, form_overlay:)
        apply_item_order_overlay(auto_order_rows(rows), group_name, form_overlay)
      end

      def auto_order_rows(rows)
        parsed = rows.map.with_index { |row, idx| order_annotation(row, idx) }
        numbered = parsed.select { |row| row[:major] }
        return rows if numbered.size < 3

        unique_keys = numbered.map { |row| [row[:major], row[:letter]] }.uniq.size
        return rows if unique_keys < numbered.size * NUMBERED_UNIQUE_RATIO

        other_parents = parsed.select { |row| row[:major] && other_code(parse_pick_list(row[:row]['pick_list_options'])) }
        last_numbered = nil
        parsed.each do |row|
          if row[:major]
            last_numbered = row
            next
          end
          next unless row[:follow_up]

          parent = other_parents.first if row[:row]['label'].match?(OTHER_LABEL) && other_parents.size == 1
          parent ||= last_numbered
          row[:sort] = if parent
            [2, parent[:major], parent[:letter], 1, row[:idx]]
          else
            [3, 0, '', 0, row[:idx]]
          end
        end

        parsed.sort_by { |row| row[:sort] }.map { |row| row[:row] }
      end

      def apply_item_order_overlay(rows, group_name, form_overlay)
        specs = form_overlay.dig('item_order', group_name)
        return rows if specs.blank?

        ordered = rows.dup
        specs.each do |link_id, spec|
          after_id = spec.is_a?(Hash) ? spec['after'] : nil
          next if after_id.blank?

          from_idx = ordered.index { |row| row['link_id'] == link_id }
          unless from_idx
            @warnings << Warning.new(
              kind: :item_order,
              identifier: rows.first&.fetch('identifier', nil),
              title: rows.first&.fetch('legacy_assessment_name', nil),
              link_id: link_id,
              label: group_name,
              detail: 'item_order link_id not in group',
            )
            next
          end

          item = ordered.delete_at(from_idx)
          to_idx = ordered.index { |row| row['link_id'] == after_id }
          unless to_idx
            ordered.insert(from_idx, item)
            @warnings << Warning.new(
              kind: :item_order,
              identifier: rows.first&.fetch('identifier', nil),
              title: rows.first&.fetch('legacy_assessment_name', nil),
              link_id: after_id,
              label: group_name,
              detail: "item_order after: #{after_id} not in group",
            )
            next
          end

          ordered.insert(to_idx + 1, item)
        end
        ordered
      end

      def order_annotation(row, idx)
        label = row['label'].to_s
        number = parse_number(label)
        if number
          major, letter = number
          return { row: row, idx: idx, major: major, letter: letter, sort: [2, major, letter, 0, idx] }
        end

        return { row: row, idx: idx, sort: [0, 0, '', 0, idx] } if label.match?(START_DATE_LABEL)
        return { row: row, idx: idx, sort: [1, 0, '', 0, idx] } if label.match?(PRE_SURVEY_LABEL)

        section = LETTERED_SECTION_LABEL.match(label)
        if section
          rank = section[1].upcase.ord - 'A'.ord + 1
          return { row: row, idx: idx, sort: [1, rank, '', 0, idx] }
        end

        { row: row, idx: idx, follow_up: true }
      end

      def parse_number(label)
        match = NUMBERED_LABEL.match(label.to_s)
        return unless match

        [match[1].to_i, match[2].to_s.downcase]
      end

      def build_items(identifier, rows, form_overlay, form_generated)
        built = []
        rows.each do |row|
          item = question_item(identifier, row)
          apply_hidden!(item, row, form_overlay)
          apply_enable_when!(identifier, item, row, built, form_overlay, form_generated)
          built << item
        end
        built
      end

      def question_item(identifier, row)
        title = @form_titles[identifier]
        options = parse_pick_list(row['pick_list_options'])
        original_type = row['form_item_type']
        type = original_type
        type = 'CHOICE' if type.blank? && options.any?
        missing_choice = type == 'CHOICE' && options.empty?
        unrecognized_type = original_type.present? && ALLOWED_TYPES.exclude?(original_type)
        type = 'STRING' if missing_choice || type.blank? || ALLOWED_TYPES.exclude?(type)

        if missing_choice || (row['form_item_type'].blank? && options.empty?)
          @warnings << Warning.new(
            kind: :choice_to_string,
            identifier: identifier,
            title: title,
            link_id: row['link_id'],
            label: row['label'],
            detail: 'CHOICE missing pick list (or blank type); emitted as STRING',
          )
        end

        if unrecognized_type
          @warnings << Warning.new(
            kind: :unrecognized_type,
            identifier: identifier,
            title: title,
            link_id: row['link_id'],
            label: row['label'],
            detail: "form_item_type #{original_type.inspect} not recognized; emitted as STRING",
          )
        end

        if row['label'].match?(MULTISELECT_LABEL)
          @warnings << Warning.new(
            kind: :implied_multiselect,
            identifier: identifier,
            title: title,
            link_id: row['link_id'],
            label: row['label'],
            detail: 'text implies multi-select; field is single-select because the CDED is not repeating',
          )
        end

        if row['label'].match?(DO_NOT_USE_LABEL)
          @warnings << Warning.new(
            kind: :do_not_use,
            identifier: identifier,
            title: title,
            link_id: row['link_id'],
            label: row['label'],
            detail: row['link_id'],
          )
        end

        item = {
          'type' => type,
          'link_id' => row['link_id'],
          'text' => row['label'],
          'mapping' => { 'custom_field_key' => row['key'] },
        }
        item['_comment'] = 'CHOICE converted to STRING; pick list pending' if missing_choice || (row['form_item_type'].blank? && options.empty?)
        item['_comment'] = "form_item_type #{original_type.inspect} not recognized; emitted as STRING" if unrecognized_type
        item['pick_list_options'] = order_pick_list(options).map { |code| { 'code' => code } } if type == 'CHOICE'
        item
      end

      def parse_pick_list(raw)
        raw.to_s.split('|').map(&:strip).reject(&:blank?)
      end

      # Yes/No/DK/refused/DNC (and HUD-suffixed aliases) in that order when every option maps.
      # Otherwise numeric codes sort by value so "10" follows "9"; non-numeric codes stay after, original order.
      def order_pick_list(codes)
        return codes if codes.size < 2

        hud_ranks = codes.map { |code| hud_pick_rank(code) }
        return codes.each_with_index.sort_by { |_, idx| [hud_ranks[idx], idx] }.map(&:first) if hud_ranks.all?

        codes.each_with_index.sort_by do |code, idx|
          number = numeric_pick_code(code)
          number ? [0, number, idx] : [1, idx, 0]
        end.map(&:first)
      end

      def hud_pick_rank(code)
        normalized = code.to_s.sub(/\s*\(HUD\)\s*\z/i, '').strip
        return 0 if normalized.match?(/\Ayes\z/i)
        return 1 if normalized.match?(/\Ano\z/i)
        return 2 if normalized.match?(/\A(client\s+)?((doesn['’]?t)|(does not)|(don['’]?t))\s+know\z/i)
        return 3 if normalized.match?(/\A(client\s+)?prefers not to answer\z/i)
        return 3 if normalized.match?(/\A(client\s+)?refused\z/i)
        return 4 if normalized.match?(/\Adata not collected\z/i)

        nil
      end

      def numeric_pick_code(code)
        Float(code)
      rescue ArgumentError, TypeError
        nil
      end

      def apply_hidden!(item, row, form_overlay)
        return unless form_overlay.dig('hidden', row['link_id']) || row['label'].match?(DO_NOT_USE_LABEL)

        item['hidden'] = true
      end

      def apply_enable_when!(identifier, item, row, prior_items, form_overlay, form_generated)
        overlay_value = overlay_enable_when(form_overlay, row['link_id'])
        if overlay_value
          form_generated['enable_when'][row['link_id']] = overlay_value
          assign_enable_when(item, overlay_value)
          record_enable_when_summary(identifier, row, overlay_value, prior_items)
          return
        end

        inferred = infer_enable_when(row, prior_items)
        return unless inferred

        form_generated['enable_when'][row['link_id']] = inferred
        assign_enable_when(item, inferred)
        record_enable_when_summary(identifier, row, inferred, prior_items)
      end

      def record_enable_when_summary(identifier, row, value, prior_items)
        condition = value.is_a?(Hash) ? value['enable_when']&.first : nil
        return unless condition

        parent = prior_items.find { |prior| prior['link_id'] == condition['question'] }
        parent_label = parent&.fetch('text', nil) || condition['question']
        @warnings << Warning.new(
          kind: :inferred_enable_when,
          identifier: identifier,
          title: @form_titles[identifier],
          link_id: row['link_id'],
          label: row['label'],
          detail: "\"#{row['label']}\" is shown when \"#{parent_label}\" is #{condition['answer_code']}",
        )
      end

      def overlay_enable_when(form_overlay, link_id)
        enable_when = form_overlay['enable_when']
        return unless enable_when&.key?(link_id)

        enable_when[link_id]
      end

      def assign_enable_when(item, value)
        return if value.blank?

        item['enable_behavior'] = value['enable_behavior'] || 'ALL'
        item['enable_when'] = value['enable_when']
      end

      def infer_enable_when(row, prior_items)
        label = row['label']
        want_other = label.match?(OTHER_LABEL)
        want_yes = label.match?(IF_YES_LABEL) && !want_other
        return unless want_other || want_yes

        matches = prior_items.select { |prior| prior['type'] == 'CHOICE' }.select do |prior|
          codes = (prior['pick_list_options'] || []).map { |opt| opt['code'] }
          want_other ? other_code(codes) : yes_code(codes)
        end
        return unless matches.size == 1

        codes = (matches.first['pick_list_options'] || []).map { |opt| opt['code'] }
        answer = want_other ? other_code(codes) : yes_code(codes)
        return unless answer

        {
          'enable_behavior' => 'ALL',
          'enable_when' => [
            { 'question' => matches.first['link_id'], 'operator' => 'EQUAL', 'answer_code' => answer },
          ],
        }
      end

      def other_code(codes)
        codes.find { |code| code.casecmp('Other').zero? } || codes.find { |code| code.match?(/\Aother\b/i) }
      end

      def yes_code(codes)
        codes.find { |code| code.casecmp('Yes').zero? } || codes.find { |code| code.match?(/\Ayes\b/i) }
      end

      def assessment_date_item(used_link_ids)
        {
          'type' => 'DATE',
          'link_id' => unique_link_id(ASSESSMENT_DATE_LINK_ID, used_link_ids),
          'text' => 'Assessment Date',
          'required' => true,
          'assessment_date' => true,
          'initial' => [
            { 'initial_behavior' => 'IF_EMPTY', 'value_local_constant' => '$today' },
          ],
          'mapping' => { 'field_name' => 'assessmentDate' },
        }
      end

      # For forms with more than one group, the assessment date gets its own leading
      # "Details" group rather than being tacked onto the front of the first real group.
      def details_group(used_link_ids)
        {
          'type' => 'GROUP',
          'link_id' => unique_link_id(slug('Details'), used_link_ids),
          'text' => 'Details',
          'item' => [assessment_date_item(used_link_ids)],
        }
      end

      def slug(text)
        s = text.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')
        s = 'group' if s.blank?
        s = "g_#{s}" unless s.match?(/\A[a-zA-Z_$]/)
        s
      end

      def unique_link_id(base, used)
        candidate = base
        n = 2
        while used.include?(candidate)
          candidate = "#{base}_#{n}"
          n += 1
        end
        used.add(candidate)
        candidate
      end

      def validate_form(identifier, document)
        errors = ::Hmis::Form::DefinitionValidator.perform(
          document.deep_stringify_keys,
          'CUSTOM_ASSESSMENT',
          skip_cded_validation: true,
        )
        errors.each do |error|
          @validator_errors << {
            identifier: identifier,
            title: @form_titles[identifier],
            message: error.full_message,
          }
        end
      end

      def load_overlay
        return { 'forms' => {} } unless File.exist?(@overlay_path)

        data = YAML.safe_load(File.read(@overlay_path), permitted_classes: [Date, Time, Symbol], aliases: true)
        data.is_a?(Hash) ? data.deep_stringify_keys : { 'forms' => {} }
      end

      def merge_overlay(existing, generated)
        forms = (existing['forms'] || {}).dup
        generated.fetch('forms').each do |identifier, data|
          prev = forms[identifier] || {}
          merged = {
            'invented_group_names' => (data['invented_group_names'] || {}).merge(prev['invented_group_names'] || {}),
            'flattened_subassessments' => ((prev['flattened_subassessments'] || []) | (data['flattened_subassessments'] || [])),
            'enable_when' => (data['enable_when'] || {}).merge(prev['enable_when'] || {}),
          }
          merged['groups'] = prev['groups'] if prev.key?('groups')
          merged['item_order'] = prev['item_order'] if prev.key?('item_order')
          merged['hidden'] = prev['hidden'] if prev.key?('hidden')
          forms[identifier] = merged
        end
        { 'forms' => forms }
      end

      def write_overlay(overlay)
        File.write(@overlay_path, "#{overlay.to_yaml}\n")
      end

      def write_zip
        require 'zip'

        timestamp = Time.current.strftime('%Y%m%d%H%M%S')
        path = File.join(File.dirname(@output_dir), "#{timestamp}_custom_forms.zip")
        FileUtils.rm_f(path)
        Zip::File.open(path, create: true) do |zip_file|
          Dir.glob(File.join(@output_dir, '*.json')).each do |file_path|
            zip_file.add(File.basename(file_path), file_path)
          end
        end
        path
      end

      def print_summary(form_count, zip_path)
        puts "Wrote #{form_count} form definition(s) to #{@output_dir}"
        puts "Zipped forms to #{zip_path}" if zip_path
        puts "Skipped #{@skipped_rows} row(s) with a blank form_definition_identifier" if @skipped_rows.positive?
        print_warning_section('Inferred conditional logic', :inferred_enable_when, use_detail_only: true)
        print_warning_section('CHOICE converted to STRING', :choice_to_string)
        print_warning_section('Unrecognized form_item_type converted to STRING', :unrecognized_type, use_detail_only: true)
        print_warning_section('Implied multi-select kept single-select', :implied_multiselect)
        print_warning_section('Do-not-use / ignore / disregard fields', :do_not_use)
        print_warning_section('Invented groups', :invented_group)
        print_warning_section('Flattened subassessments', :flattened_subassessment)
        print_warning_section('Item-order overlay misses', :item_order)

        puts
        if @validator_errors.any?
          puts "Validator errors (#{@validator_errors.size}):"
          @validator_errors.each do |error|
            puts "  #{form_heading(error[:title], error[:identifier])}: #{error[:message]}"
          end
        else
          puts 'All forms passed DefinitionValidator (skip_cded_validation: true).'
        end
      end

      def print_warning_section(heading, kind, use_detail_only: false)
        items = @warnings.select { |warning| warning.kind == kind }
        puts
        puts "#{heading} (#{items.size}):"
        if items.empty?
          puts '  (none)'
          return
        end
        items.each do |warning|
          body = if use_detail_only
            warning.detail
          else
            [warning.label, warning.detail].compact.reject(&:blank?).join(' — ')
          end
          puts "  #{form_heading(warning.title, warning.identifier)}: #{body}"
        end
      end

      def form_heading(title, identifier)
        display_title = title.presence || identifier
        "#{display_title} (#{identifier})"
      end
    end
  end
end
