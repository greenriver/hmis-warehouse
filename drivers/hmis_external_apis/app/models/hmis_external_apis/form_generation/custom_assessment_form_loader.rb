###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'fileutils'
require 'json'

# Publishes Form Builder–managed Custom Assessment definitions from JSON files.
# Does not use JsonForms / form_data (those set managed_in_version_control and
# overwrite on seed).
#
# Always publishes directly — there is no draft step. Meant for the initial,
# one-time load of freshly generated forms straight into production, where
# CDEDs need to exist immediately for the dbt migration pipeline. If a
# published version already exists for an identifier, it is retired and the
# new one is published in its place (version + 1).
#
# If a customer has since created their own draft for an identifier (e.g. to
# reorder or relabel questions in Form Builder), that draft is deleted before
# publishing — re-running this tool discards any in-progress Form Builder
# edits for the identifiers in dir. Only re-run this after the initial
# production load if you are fixing a generation bug and are OK discarding
# any customer edits made since. In dry_run mode nothing is deleted; existing
# drafts are only reported.
module HmisExternalApis
  module FormGeneration
    class CustomAssessmentFormLoader
      ROLE = 'CUSTOM_ASSESSMENT'

      Result = Struct.new(:action, :identifier, :title, :detail, keyword_init: true)

      def self.call(...) = new(...).call

      def initialize(dir:, data_source_id: nil, dry_run: false, only: [])
        @dir = dir.to_s
        @data_source_id = data_source_id
        @dry_run = dry_run
        @only = Array(only).map(&:to_s).reject(&:blank?)
        @results = []
        @errors = []
      end

      def call
        @data_source = resolve_data_source
        import
        print_summary
        { results: @results, errors: @errors, success: @errors.empty? }
      end

      private

      def resolve_data_source
        return ::GrdaWarehouse::DataSource.hmis.find(@data_source_id) if @data_source_id.present?

        ::GrdaWarehouse::DataSource.hmis.sole
      rescue ActiveRecord::SoleRecordExceeded
        raise 'Multiple HMIS data sources exist; pass data_source_id:'
      end

      def import
        files = json_files(@dir)
        files.each do |path|
          payload = parse_file(path)
          next if skip_identifier?(payload[:identifier])

          unless payload[:role].to_s == ROLE
            @errors << Result.new(
              action: :error,
              identifier: payload[:identifier],
              title: payload[:title],
              detail: "role #{payload[:role].inspect} is not #{ROLE}",
            )
            next
          end

          publish_one(payload)
        rescue StandardError => e
          @errors << Result.new(action: :error, identifier: File.basename(path, '.json'), title: nil, detail: e.message)
        end
      end

      def publish_one(payload)
        identifier = payload[:identifier]
        title = payload[:title]
        definition_json = payload[:definition]
        versions = definitions_for(identifier)
        draft = versions.find(&:draft?)
        previous_published = versions.find(&:published?)

        log_result(:draft_exists, identifier, title, "draft v#{draft.version} exists and would be deleted (its edits would be lost)") if draft && @dry_run

        next_version = previous_published ? previous_published.version + 1 : 0
        if @dry_run
          detail = if previous_published
            "would retire published v#{previous_published.version} (WARNING: may include customer edits) and publish v#{next_version}"
          else
            "would publish v#{next_version}"
          end
          return log_result(:publish, identifier, title, detail)
        end

        publish!(identifier: identifier, title: title, definition: definition_json, version: next_version, previous_published: previous_published, draft: draft)
      end

      # draft, if present, is only destroyed once the transaction below actually commits a new
      # published version — a failed publish (invalid definition, JSON-form validation errors)
      # rolls back the draft destroy along with everything else, so it isn't lost for nothing.
      def publish!(identifier:, title:, definition:, version:, previous_published:, draft:)
        new_definition = ::Hmis::Form::Definition.new(
          identifier: identifier,
          title: title,
          role: ROLE,
          version: version,
          status: ::Hmis::Form::Definition::PUBLISHED,
          definition: definition,
          data_source_id: @data_source.id,
          managed_in_version_control: false,
        )
        unless new_definition.valid?
          @errors << Result.new(action: :publish_failed, identifier: identifier, title: title, detail: "Definition invalid: #{new_definition.errors.full_messages.join(', ')}")
          return
        end

        errors = []
        ::Hmis::Form::Definition.transaction do
          previous_published&.update!(status: ::Hmis::Form::Definition::RETIRED)
          draft&.destroy!
          cdeds = ::Hmis::Form::CustomDataElementGenerator.new(
            definition: new_definition,
            create_missing_mappings: true,
            data_source: @data_source,
          ).run
          cdeds.each(&:save!)
          errors = new_definition.validate_json_form
          raise ActiveRecord::Rollback if errors.any?

          new_definition.save!
        end

        if errors.any?
          messages = errors.map(&:full_message).join('; ')
          @errors << Result.new(action: :publish_failed, identifier: identifier, title: title, detail: messages)
          return
        end

        log_result(:deleted_draft, identifier, title, "deleted draft v#{draft.version} id=#{draft.id}") if draft
        log_result(:publish, identifier, title, "published v#{version} id=#{new_definition.id}")
      end

      def definitions_for(identifier)
        ::Hmis::Form::Definition.
          in_data_source(@data_source.id).
          where(identifier: identifier).
          order(version: :desc).
          to_a
      end

      def parse_file(path)
        raw = JSON.parse(File.read(path))
        filename_identifier = File.basename(path, '.json')
        if raw.key?('item')
          return {
            identifier: filename_identifier,
            title: raw['name'].presence || filename_identifier,
            role: ROLE,
            definition: raw,
          }
        end

        identifier = raw['identifier'].presence || filename_identifier
        raise "identifier #{identifier.inspect} does not match filename #{filename_identifier.inspect}" if identifier != filename_identifier

        definition = raw['definition']
        raise 'envelope JSON is missing definition' unless definition.is_a?(Hash)

        {
          identifier: identifier,
          title: raw['title'].presence || definition['name'].presence || identifier,
          role: raw['role'].presence || ROLE,
          definition: definition,
        }
      end

      def json_files(dir)
        raise "directory not found: #{dir}" unless Dir.exist?(dir)

        Dir.glob(File.join(dir, '*.json')).sort
      end

      def skip_identifier?(identifier)
        @only.any? && @only.exclude?(identifier)
      end

      def log_result(action, identifier, title, detail)
        @results << Result.new(action: action, identifier: identifier, title: title, detail: detail)
      end

      def print_summary
        mode = @dry_run ? 'dry-run ' : ''
        puts "#{mode}import against data_source_id=#{@data_source.id} dir=#{@dir}"
        if @results.empty? && @errors.empty?
          puts '  (no files)'
          return
        end
        @results.each do |result|
          puts "  #{heading(result.title, result.identifier)} [#{result.action}]: #{result.detail}"
        end
        return if @errors.empty?

        puts
        puts "Errors (#{@errors.size}):"
        @errors.each do |error|
          puts "  #{heading(error.title, error.identifier)} [#{error.action}]: #{error.detail}"
        end
      end

      def heading(title, identifier)
        display = title.presence || identifier
        "#{display} (#{identifier})"
      end
    end
  end
end
