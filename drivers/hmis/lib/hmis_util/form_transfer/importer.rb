###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Loads a file written by Exporter into this installation's HMIS data source.
    class Importer
      include Logging

      DEVELOPMENT_NAME_PREFIX = 'REAL - '
      UNGUARDED_ENVIRONMENTS = ['development', 'test'].freeze
      CONFIRMATION_ENV_VAR = 'CONFIRM_IMPORT_INTO'

      class DryRunRollback < StandardError; end

      def self.from_file(path, **options)
        new(JSON.parse(File.read(path)), **options)
      end

      # The import writes projects, organizations, and configuration, so outside development the
      # caller has to name the environment. The error doesn't print the expected value.
      def self.check_environment!(confirm_environment)
        return if Rails.env.in?(UNGUARDED_ENVIRONMENTS)
        return if confirm_environment.to_s == Rails.env

        raise 'Refusing to import outside development: this writes projects, organizations, and HMIS configuration into a real installation. ' \
              "If that's intended, set #{CONFIRMATION_ENV_VAR} to the name of this Rails environment."
      end

      # @param name_prefix [String, nil] prepended to imported organization and project names
      # @param confirm_environment [String, nil] must equal Rails.env outside development and test
      def initialize(
        payload,
        data_source_id: FormTransfer.default_data_source_id,
        dry_run: false,
        name_prefix: default_name_prefix,
        confirm_environment: nil,
        output: $stdout
      )
        self.class.check_environment!(confirm_environment)
        raise "Unsupported format_version #{payload['format_version']}, expected one of #{READABLE_FORMAT_VERSIONS}" unless payload['format_version'].in?(READABLE_FORMAT_VERSIONS)

        @payload = payload
        @data_source_id = GrdaWarehouse::DataSource.hmis.find(data_source_id).id
        @dry_run = dry_run
        @name_prefix = name_prefix
        @output = output
      end

      # CE settings live in the primary database and everything else in the warehouse database,
      # so both are wrapped. requires_new keeps a dry run's rollback inside any caller's transaction.
      def run
        ApplicationRecord.transaction(requires_new: true) do
          GrdaWarehouseBase.transaction(requires_new: true) do
            import_all
            raise DryRunRollback if @dry_run
          end
        end
      rescue DryRunRollback
        @output.puts('DRY_RUN: rolled back')
      end

      private

      def default_name_prefix
        DEVELOPMENT_NAME_PREFIX if Rails.env.development?
      end

      def import_all
        hud_user_id = Hmis::Hud::User.system_user(data_source_id: @data_source_id).user_id
        forms = FormImporter.new(@payload, data_source_id: @data_source_id, user_id: hud_user_id, output: @output)
        projects = ProjectImporter.new(@payload, data_source_id: @data_source_id, user_id: hud_user_id, name_prefix: @name_prefix, output: @output)
        ce = CeImporter.new(@payload.fetch('ce', {}), data_source_id: @data_source_id, projects: projects, output: @output)

        forms.import_forms
        projects.run
        ce.run
        ProjectConfigImporter.new(@payload.fetch('project_configs', []), data_source_id: @data_source_id, projects: projects, output: @output).run
        ce.import_match_rules
        forms.import_rules(projects: projects)
      end
    end
  end
end
