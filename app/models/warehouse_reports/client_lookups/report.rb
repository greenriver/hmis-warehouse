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

      # One plucked row. `project_id` and `enrollment_id` are always fetched (even when
      # not mapping enrollments) because they're needed internally: `enrollment_id` is a
      # unique, non-null tie-breaker in the query's ORDER BY (see `order_columns`), and
      # `project_id` drives the per-row PII policy lookup.
      PluckedRow = Struct.new(:ds_name, :personal_id, :destination_id, :first_name, :last_name, :enrollment_hud_id, :enrollment_id, :project_id) do
        def display_key
          [ds_name, personal_id, destination_id, first_name, last_name]
        end
      end

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

      def to_xlsx
        Axlsx::Package.new do |package|
          package.workbook.add_worksheet(name: 'Client Lookup') do |sheet|
            title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
            sheet.add_row(headers, style: title)
            rows.each { |row| sheet.add_row(row) }
          end
        end.to_stream.read
      end

      # The Project picker is scoped to `:can_view_assigned_reports` (see
      # `project_source`), but a project id can still reach here via hand-crafted
      # params. Lets the controller distinguish "nothing selected" from "selected,
      # but none of it is authorized" so it can show a clear message instead of
      # silently exporting an empty file.
      def any_authorized_projects?
        authorized_project_ids.present?
      end

      private

      attr_reader :filter, :user

      def map_enrollments?
        @map_enrollments
      end

      # Rows are plucked in batches (rather than all at once) to bound memory use
      # on large exports.
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
            batch.each { |row| rows << redact_row(row, policy_for_project(row.project_id)) }
          else
            batch.each do |row|
              if pending_key && row.display_key != pending_key
                rows << flush_group(pending_group)
                pending_group = []
              end
              pending_key = row.display_key
              pending_group << row
            end
          end
        end
        rows << flush_group(pending_group) if pending_group.any?

        rows
      end

      # `order_columns` ends with the enrollment id, a unique, non-null column, so the
      # query's ORDER BY is a strict total order with no ties. That matters here: each
      # call below is a separate query execution, and without a unique tie-breaker
      # Postgres offers no guarantee that rows tied on the other sort columns come back
      # in the same relative order on every execution. If they didn't, a client's rows
      # could be split differently across the OFFSET boundary between two calls, and a
      # row could be silently skipped or duplicated — corrupting both the PII redaction
      # decision in `flush_group` and the exported row count.
      def each_batch
        offset = 0
        loop do
          batch = query.limit(BATCH_SIZE).offset(offset).pluck(*pluck_columns).map { |values| PluckedRow.new(*values) }
          break if batch.empty?

          yield batch
          break if batch.size < BATCH_SIZE

          offset += BATCH_SIZE
        end
      end

      def flush_group(group)
        policy = group.any? { |row| policy_for_project(row.project_id).can_view_name? } ? allow_pii_policy : deny_pii_policy
        redact_row(group.first, policy)
      end

      # The candidate project ids are bounded by the filter's selection (data
      # sources/orgs/project groups/etc), not by row or enrollment count, so this
      # is preloaded once up front rather than derived per-batch from plucked rows.
      # We preload only the *authorized* subset, since that's exactly the set of
      # project ids the query can surface (and thus the only ids `policy_for_project`
      # is ever asked about).
      def preload_policies
        project_ids = authorized_project_ids
        user.policy_context.preload_project_dependencies(project_ids) if project_ids.present?
      end

      # The filter's selected project ids, narrowed to those the user is actually
      # authorized to view for this report (see `project_source`). Memoized because
      # it's consumed both by the controller's pre-export authorization check and by
      # `preload_policies`.
      def authorized_project_ids
        @authorized_project_ids ||= project_source.where(id: filter.effective_project_ids).pluck(:id)
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

      def redact_row(row, policy)
        display_row = [
          row.ds_name,
          row.personal_id,
          row.destination_id,
          GrdaWarehouse::PiiProvider.viewable_name(row.first_name, policy: policy),
          GrdaWarehouse::PiiProvider.viewable_name(row.last_name, policy: policy),
        ]
        return display_row unless map_enrollments?

        display_row + [row.enrollment_hud_id, row.enrollment_id]
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

      # Matches `PluckedRow`'s field order. Always includes the enrollment and project
      # columns — see the comments on `PluckedRow` and `each_batch` for why.
      def pluck_columns
        [ds_t[:name], :PersonalID, wc_t[:destination_id], :FirstName, :LastName, e_t[:EnrollmentID], e_t[:id], p_t[:id]]
      end

      # Must cover every column in `PluckedRow#display_key` before the `enrollment_id`
      # tie-breaker. `build_rows` groups a client's rows by contiguous equal `display_key`,
      # which only holds if rows sharing a `display_key` sort adjacently. `PersonalID` is
      # part of the key but not otherwise implied by the other sort columns (two source
      # clients in the same data source can share a warehouse `destination_id` and name
      # while differing only by `PersonalID`), so it must appear here — otherwise those
      # rows interleave by `enrollment_id` and a single client is emitted as duplicate rows.
      def order_columns
        [ds_t[:name].asc, wc_t[:destination_id].asc, c_t[:PersonalID].asc, c_t[:LastName].asc, c_t[:FirstName].asc, e_t[:id].asc]
      end
    end
  end
end
