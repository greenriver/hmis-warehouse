###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Every project config in the data source (auto-enter, auto-exit, CE, staff assignment, ...).
    class ProjectConfigExporter
      RECEIVES_FROM = Hmis::ProjectCeConfig::RECEIVES_DIRECT_REFERRALS_FROM

      def initialize(data_source_id:, refs:)
        @data_source_id = data_source_id
        @refs = refs
      end

      # A config whose project, organization, or referral source can't be resolved is left out
      # (ReferenceTracker records a warning): without its scope it can't be saved, and an emptied
      # receives_direct_referrals_from would accept referrals from every project.
      def build
        Hmis::ProjectConfig.where(data_source_id: @data_source_id).order(:id).filter_map do |config|
          context = "#{config.type} #{config.id}"
          project_hud_id = @refs.project_hud_id(config.project_id, context: context)
          organization_hud_id = @refs.organization_hud_id(config.organization_id, context: context)
          next if (config.project_id && !project_hud_id) || (config.organization_id && !organization_hud_id)

          options = export_options(config, context)
          next if options == :unresolved

          { type: config.type, project_hud_id: project_hud_id, organization_hud_id: organization_hud_id, project_type: config.project_type, options: options }
        end
      end

      private

      # receives_direct_referrals_from holds project database ids, which differ between installations.
      def export_options(config, context)
        return unless config.config_options

        options = config.options
        return options unless options.key?(RECEIVES_FROM)

        hud_ids = Array.wrap(options[RECEIVES_FROM]).map { |id| @refs.project_hud_id(id, context: context) }
        return :unresolved if hud_ids.any?(&:nil?)

        options.merge(RECEIVES_FROM => hud_ids)
      end
    end
  end
end
