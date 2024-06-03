###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module ViewConfiguration
    extend ActiveSupport::Concern

    included do
      after_initialize :filter

      def title
        Translation.translate('All Neighbors System Dashboard')
      end
      alias_method :instance_title, :title

      private def public_s3_directory
        'all-neighbors-system-dashboard'
      end

      # TODO: update once we have the internal version
      def mask_small_populations?
        true
      end

      def report_path_array
        [
          :all_neighbors_system_dashboard,
          :warehouse_reports,
          :reports,
        ]
      end

      def controller_class
        AllNeighborsSystemDashboard::WarehouseReports::ReportsController
      end

      def raw_layout
        'external'
      end

      def default_project_type_codes
        HudUtility2024.performance_reporting.keys
      end

      def project_type_ids
        filter.project_type_ids
      end

      def multiple_project_types?
        true
      end

      def filter=(filter_object)
        self.options = filter_object.to_h
        # force reset the filter cache
        @filter = nil
        filter
      end

      def filter
        @filter ||= begin
          f = ::Filters::HudFilterBase.new(
            user_id: user_id,
            enforce_one_year_range: false,
          )
          f.update(options.with_indifferent_access.merge(enforce_one_year_range: false)) if options.present?
          f
        end
      end

      def describe_filter_as_html(keys = nil, inline: false)
        keys ||= [
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
          :secondary_project_ids,
          :secondary_project_group_ids,
        ]
        filter.describe_filter_as_html(keys, inline: inline, labels: { secondary_projects: 'Diversion Projects', secondary_project_groups: 'DRTRR Project Group' })
      end

      def known_params
        [
          :start,
          :end,
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
          :secondary_project_ids,
          :secondary_project_group_ids,
        ]
      end

      private def build_control_sections
        [
          build_funding_section,
        ]
      end
    end
  end
end
