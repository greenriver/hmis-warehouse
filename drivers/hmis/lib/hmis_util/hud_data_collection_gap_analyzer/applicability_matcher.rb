###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class HudDataCollectionGapAnalyzer
    # Decides whether HUD requires Current Living Situation or a given Service record type
    # for a project.
    #
    # Applicability entries omit keys to mean "any": { funder: 5 } applies at every project
    # type, and { project_type: 1 } applies under every funder. Treating these as exact
    # tuples to match against would report a gap for every funder-only rule.
    class ApplicabilityMatcher
      attr_reader :project, :funder_codes

      # @param project [GrdaWarehouse::Hud::Project]
      # @param funder_codes [Array<Integer>] HUD funding source codes on this project
      def initialize(project:, funder_codes:)
        @project = project
        @funder_codes = funder_codes
      end

      def current_living_situation_required?
        hud.current_living_situation_funder_applicability_requirements.any? do |entry|
          matches?(entry)
        end
      end

      # @return [Array<Integer>] HUD Service RecordType codes HUD requires for this project
      def required_service_record_types
        hud.service_form_funder_applicability_requirements.filter_map do |config|
          config[:record_type] if config[:applicability_requirements].any? { |entry| matches?(entry) }
        end
      end

      protected

      def matches?(entry)
        matches_funder?(entry) && matches_project_type?(entry)
      end

      def matches_funder?(entry)
        return true if entry[:funder].nil?

        funder_codes.include?(entry[:funder])
      end

      def matches_project_type?(entry)
        return true if entry[:project_type].nil?

        project.project_type == entry[:project_type]
      end

      def hud
        @hud ||= HudHelper.util(HUD_VERSION)
      end
    end
  end
end
