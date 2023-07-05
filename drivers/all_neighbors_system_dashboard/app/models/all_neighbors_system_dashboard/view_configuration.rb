###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module ViewConfiguration
    extend ActiveSupport::Concern

    included do
      after_initialize :filter

      def title
        _('All Neighbors System Dashboard')
      end

      def report_path_array
        [
          :all_neighbors_system_dashboard,
          :warehouse_reports,
          :all_neighbors_system_dashboards,
        ]
      end

      def default_project_type_codes
        [:ph, :oph, :rrh, :psh]
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
          f = ::Filters::FilterBase.new(
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
        ]
        filter.describe_filter_as_html(keys, inline: inline, secondary_projects_label: _('Associated CE Projects'))
      end

      def known_params
        [
          :start,
          :end,
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
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
