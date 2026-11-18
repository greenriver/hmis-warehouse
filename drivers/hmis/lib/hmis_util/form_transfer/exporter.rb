###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Writes the selected form definitions, and everything they depend on, to a JSON file that
    # Importer reads.
    class Exporter
      # @param identifiers [Array<String>, nil] form identifiers to export; all when blank
      # @param roles [Array<String>, nil] form roles to export; all when blank
      # @param extra_project_ids [Array<String>] HUD ProjectIDs to export even when nothing else references them
      def initialize(
        data_source_id: FormTransfer.default_data_source_id,
        identifiers: nil,
        roles: nil,
        include_projects: true,
        include_ce: true,
        extra_project_ids: [],
        source_host: nil,
        output: $stdout
      )
        @data_source_id = GrdaWarehouse::DataSource.hmis.find(data_source_id).id
        @identifiers = Array.wrap(identifiers).compact_blank
        @roles = Array.wrap(roles).compact_blank
        @include_projects = include_projects
        @include_ce = include_ce
        @extra_project_ids = Array.wrap(extra_project_ids).compact_blank
        @source_host = source_host
        @output = output
      end

      # @return [Hash] the exported payload
      def write(path)
        payload = build
        File.write(path, JSON.pretty_generate(payload))
        @output.puts("Wrote #{path}: #{summary(payload)}")
        payload[:warnings].each { |warning| @output.puts("WARNING: #{warning}") }
        payload
      end

      def build
        refs = ReferenceTracker.new(data_source_id: @data_source_id)
        ce_exporter = CeExporter.new(data_source_id: @data_source_id, refs: refs)
        ce = @include_ce ? ce_exporter.build : {}
        forms = FormExporter.new(
          data_source_id: @data_source_id,
          identifiers: @identifiers,
          roles: @roles,
          required_identifiers: @include_ce ? ce_exporter.form_identifiers : [],
        )
        form_payload = forms.build
        project_configs = ProjectConfigExporter.new(data_source_id: @data_source_id, refs: refs).build
        projects = if @include_projects
          ProjectExporter.new(rules: forms.rules, extra_project_ids: @extra_project_ids, refs: refs, data_source_id: @data_source_id).build
        else
          { organizations: [], projects: [] }
        end

        {
          format_version: FORMAT_VERSION,
          exported_at: Time.current.iso8601,
          source_host: @source_host,
          **form_payload,
          project_configs: project_configs,
          ce: ce,
          **projects,
          warnings: forms.warnings + refs.warnings,
        }
      end

      private

      def summary(payload)
        counts = payload.select { |_, value| value.is_a?(Array) }.except(:warnings).map { |key, value| "#{value.size} #{key}" }
        counts += payload[:ce].map { |key, value| "#{value.size} ce.#{key}" }
        counts.join(', ')
      end
    end
  end
end
