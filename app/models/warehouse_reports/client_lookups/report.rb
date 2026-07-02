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

      BATCH_SIZE = 5_000

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
        @rows ||= build_rows
      end

      private

      attr_reader :filter, :user

      def map_enrollments?
        @map_enrollments
      end

      # Rows are plucked in batches (rather than all at once) to bound memory use
      # on large exports. Each row is plucked with the enrollment's project id
      # appended so we can check whether the user's PII policy for that project
      # allows viewing the client's name; the project id is stripped back out
      # before the row is returned.
      #
      # When not mapping enrollments, a client's row aggregates across every project
      # they were enrolled in during the range, so the name is shown if the user's
      # policy allows viewing it via any one of those projects. Since batches are
      # plucked in the query's sort order, a client's rows are always contiguous, so
      # a group is only known to be complete once a differing row is seen (possibly
      # in a later batch) — `pending_key`/`pending_group` carry an in-progress group
      # across that boundary.
      def build_rows
        preload_policies

        rows = []
        pending_key = nil
        pending_group = []

        each_batch do |batch|
          if map_enrollments?
            batch.each { |row| rows << redact_row(row[0..-2], policy_for_project(row.last)) }
          else
            batch.each do |row|
              key = row[0..-2]
              if pending_key && key != pending_key
                rows << flush_group(pending_key, pending_group)
                pending_group = []
              end
              pending_key = key
              pending_group << row
            end
          end
        end
        rows << flush_group(pending_key, pending_group) if pending_key

        rows
      end

      def each_batch
        offset = 0
        loop do
          batch = query.limit(BATCH_SIZE).offset(offset).pluck(*pluck_columns)
          break if batch.empty?

          yield batch
          break if batch.size < BATCH_SIZE

          offset += BATCH_SIZE
        end
      end

      def flush_group(display_row, group)
        policy = group.any? { |row| policy_for_project(row.last).can_view_name? } ? allow_pii_policy : deny_pii_policy
        redact_row(display_row, policy)
      end

      # The candidate project ids are bounded by the filter's selection (data
      # sources/orgs/project groups/etc), not by row or enrollment count, so this
      # is preloaded once up front rather than derived per-batch from plucked rows.
      def preload_policies
        project_ids = filter.effective_project_ids
        user.policy_context.preload_project_dependencies(project_ids) if project_ids.present?
      end

      def policy_for_project(project_id)
        user.reporting_policy_for_project(project_id: project_id, mode: :download)
      end

      def allow_pii_policy
        GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance
      end

      def deny_pii_policy
        GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
      end

      def redact_row(display_row, policy)
        ds_name, personal_id, destination_id, first_name, last_name, *rest = display_row
        [
          ds_name,
          personal_id,
          destination_id,
          GrdaWarehouse::PiiProvider.viewable_name(first_name, policy: policy),
          GrdaWarehouse::PiiProvider.viewable_name(last_name, policy: policy),
          *rest,
        ]
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

      # NOTE: the project restriction is applied as a single `merge` (via `project_source.where(...)`)
      # rather than two separate `.merge(Project.where(...))` calls. Rails' `Relation#merge` treats
      # hash-style `where` conditions on the same column as a replacement, not an AND, so merging the
      # filter's project ids and `project_source` separately would let whichever merge runs last silently
      # discard the other's restriction (e.g. the filter's single selected project would be discarded in
      # favor of every project the user can view).
      def query
        GrdaWarehouse::Hud::Client.source.
          joins(:warehouse_client_source, :data_source, enrollments: :project).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter.start..filter.end)).
          merge(project_source.where(id: filter.effective_project_ids)).
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

      # select_columns plus the enrollment's project id, used to look up the user's
      # PII policy for the row; stripped back out before rows are returned.
      def pluck_columns
        select_columns + [p_t[:id]]
      end

      def order_columns
        [ds_t[:name].asc, wc_t[:destination_id].asc, c_t[:LastName].asc, c_t[:FirstName].asc]
      end
    end
  end
end
