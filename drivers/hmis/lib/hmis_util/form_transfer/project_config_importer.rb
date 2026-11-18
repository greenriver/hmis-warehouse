###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Imports project configs, matched by type and scope (project, organization, or project type).
    class ProjectConfigImporter
      include Logging

      RECEIVES_FROM = Hmis::ProjectCeConfig::RECEIVES_DIRECT_REFERRALS_FROM

      def initialize(configs, data_source_id:, projects:, output:)
        @configs = configs
        @data_source_id = data_source_id
        @projects = projects
        @output = output
      end

      def run
        @configs.each do |attrs|
          label = "#{attrs['type'].demodulize} for #{attrs['project_hud_id'] || attrs['organization_hud_id'] || "project type #{attrs['project_type']}"}"
          project = @projects.find_project(attrs['project_hud_id'])
          organization = @projects.find_organization(attrs['organization_hud_id'])
          if (attrs['project_hud_id'] && !project) || (attrs['organization_hud_id'] && !organization)
            log("SKIP #{label}: project or organization not found locally")
            next
          end
          next log("SKIP #{attrs['type'].demodulize}: no project, organization, or project type") unless project || organization || attrs['project_type']

          options = attrs['options'] ? local_options(attrs['options']) : nil
          next log("SKIP #{label}: a project in #{RECEIVES_FROM} is not found locally") if options == :unresolved

          config = config_class(attrs['type']).find_or_initialize_by(
            data_source_id: @data_source_id,
            project_id: project&.id,
            organization_id: organization&.id,
            project_type: attrs['project_type'],
          )
          config.config_options = options&.to_json
          log_save(config, label)
        end
      end

      private

      # The type comes from the import file, so only registered config classes are constantized.
      def config_class(type)
        raise "Unknown project config type #{type}" unless Hmis::ProjectConfig::CONFIG_TYPE_FACTORIES.value?(type)

        type.constantize
      end

      # An unresolved sender can't be dropped: an emptied list accepts referrals from every project.
      def local_options(options)
        return options unless options.key?(RECEIVES_FROM)

        ids = options[RECEIVES_FROM].map { |hud_id| @projects.find_project(hud_id)&.id }
        return :unresolved if ids.any?(&:nil?)

        options.merge(RECEIVES_FROM => ids)
      end
    end
  end
end
