###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Audit
  module CohortAccess
    # Pure interval algebra used to reconstruct and combine access windows.
    # Intervals are half-open [start_at, end_at); a nil end_at means "still open".
    module Intervals
      module_function

      # Merge a list of intervals, combining any that overlap or touch, sorted by start.
      def merge(intervals)
        sorted = intervals.reject(&:nil?).sort_by(&:start_at)
        merged = []
        sorted.each do |current|
          last = merged.last
          if last && overlaps_or_touches?(last, current)
            merged[-1] = Interval.new(last.start_at, later_end(last.end_at, current.end_at))
          else
            merged << Interval.new(current.start_at, current.end_at)
          end
        end
        merged
      end

      # Intersect two or more interval lists, returning the windows covered by ALL of them.
      def intersect(*lists)
        return [] if lists.empty?
        return merge(lists.first) if lists.length == 1

        lists.reduce { |acc, list| intersect_pair(acc, list) }
      end

      # Is +time+ within any of the intervals? Half-open: inclusive of start, exclusive of end.
      def covers?(intervals, time)
        intervals.any? { |i| i.covers?(time) }
      end

      # Reconstruct the on/off intervals for a single soft-deletable, paper-trailed record from its
      # PaperTrail versions. Robust to soft-deletes recorded as either an `update` (deleted_at set) or
      # a `destroy` event, and to restore cycles (deleted_at cleared).
      #
      # +record+ is the live (with_deleted) row, or nil if it was hard-deleted. We reconcile the tail
      # of the version-derived timeline against the row's current state, because `add_viewable` restores
      # a soft-deleted row WITHOUT recording a version — so the versions can end "closed" while the row
      # is in fact active again. The restore time is approximated by the row's updated_at.
      # With no versions we fall back entirely to the row's created_at/deleted_at (pre-PaperTrail data).
      def reconstruct(versions, record: nil)
        ordered = versions.sort_by { |v| [v.created_at, v.id.to_i] }
        return fallback_intervals(record) if ordered.empty?

        intervals = run_state_machine(ordered)
        reconcile_with_record(intervals, record)
      end

      def run_state_machine(ordered_versions)
        intervals = []
        active = false
        opened_at = nil
        ordered_versions.each do |version|
          next_active = active_after?(version, active)
          if next_active && !active
            opened_at = version.created_at
            active = true
          elsif !next_active && active
            intervals << Interval.new(opened_at, version.created_at)
            active = false
          end
        end
        intervals << Interval.new(opened_at, nil) if active
        intervals
      end

      def reconcile_with_record(intervals, record)
        return intervals unless record

        machine_open = intervals.last && intervals.last.end_at.nil?
        currently_active = record.try(:deleted_at).nil?
        return intervals if machine_open == currently_active

        if currently_active
          # Restored after the last recorded event (e.g. add_viewable restore, which is not versioned).
          reopen = record.try(:updated_at) || intervals.last&.end_at
          return intervals unless reopen

          intervals + [Interval.new(reopen, nil)]
        else
          # Row is soft-deleted now but no closing version was recorded; close the open tail.
          close_at = record.try(:deleted_at) || record.try(:updated_at)
          return intervals unless close_at && intervals.any?

          last = intervals.pop
          intervals + [Interval.new(last.start_at, close_at)]
        end
      end

      def active_after?(version, currently_active)
        return false if version.event == 'destroy'

        changeset = safe_changeset(version)
        return changeset['deleted_at'][1].nil? if changeset.key?('deleted_at')
        return true if version.event == 'create'

        currently_active
      end

      def safe_changeset(version)
        version.changes_with_computed_fallback || {}
      rescue StandardError
        {}
      end

      def fallback_intervals(record)
        return [] unless record

        # Some legacy join tables (e.g. AccessGroupMember) carry no timestamps at all; treat such a
        # live row as "present since unknown" (epoch), which the per-path intersection then bounds.
        start_at = record.try(:created_at) || record.try(:updated_at) || Time.zone.at(0)
        [Interval.new(start_at, record.try(:deleted_at))]
      end

      def overlaps_or_touches?(earlier, later)
        # earlier is sorted before later, so earlier.start_at <= later.start_at
        return true if earlier.end_at.nil?

        earlier.end_at >= later.start_at
      end

      def intersect_pair(list_a, list_b)
        result = []
        list_a.each do |a|
          list_b.each do |b|
            start_at = [a.start_at, b.start_at].max
            finish = earlier_end(a.end_at, b.end_at)
            next unless finish.nil? || start_at < finish

            result << Interval.new(start_at, finish)
          end
        end
        merge(result)
      end

      # The later of two interval ends, where nil means open (later than any time).
      def later_end(first, second)
        return nil if first.nil? || second.nil?

        [first, second].max
      end

      # The earlier of two interval ends, where nil means open (later than any time).
      def earlier_end(first, second)
        return second if first.nil?
        return first if second.nil?

        [first, second].min
      end
    end
  end
end
