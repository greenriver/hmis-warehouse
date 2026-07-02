###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  module ClientLookups
    class Report
      include ArelHelper

      def initialize(filter:, user:, map_enrollments: false)
        @filter = filter
        @user = user
        @map_enrollments = map_enrollments
      end

      def headers
        return client_headers unless map_enrollments?

        client_headers + enrollment_headers
      end

      def rows
        @rows ||= query.pluck(*select_columns)
      end

      private

      attr_reader :filter, :user

      def map_enrollments?
        @map_enrollments
      end

      def client_headers
        [
          'Data Source',
          'Personal ID (from HMIS)',
          'Warehouse Client ID',
          'First Name (from HMIS)',
          'Last Name (from HMIS)',
        ]
      end

      def enrollment_headers
        [
          'Enrollment ID (from HMIS)',
          'Warehouse Enrollment ID',
        ]
      end

      def query
        GrdaWarehouse::Hud::Client.source.
          joins(:warehouse_client_source, :data_source, enrollments: :project).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter.start..filter.end)).
          merge(GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids)).
          merge(project_source).
          distinct.
          order(*order_columns)
      end

      def project_source
        GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports)
      end

      def select_columns
        client_columns = [ds_t[:name], :PersonalID, wc_t[:destination_id], :FirstName, :LastName]
        return client_columns unless map_enrollments?

        client_columns + [e_t[:EnrollmentID], e_t[:id]]
      end

      def order_columns
        [ds_t[:name].asc, wc_t[:destination_id].asc, c_t[:LastName].asc, c_t[:FirstName].asc]
      end
    end
  end
end
