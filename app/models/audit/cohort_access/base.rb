###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Audit
  module CohortAccess
    # Reconstructs the history of which users could access a cohort from PaperTrail history.
    #
    # This is an abstract base shared by the Legacy (AccessGroup) and Acl (Collection) permission
    # models. Subclasses implement the path-specific hooks; the base owns the interval math, the
    # effective-access union, the annotated event log, the summary, and CSV export.
    #
    # NOTE: this audit reflects only the structural access *relationship* (group/collection
    # assignments and memberships). It deliberately does NOT account for the role permissions a user
    # held at any time. It shows when a user *may* have had access and when they *could not* have.
    class Base
      # The disclaimer shown on the page and at the top of the CSV export.
      PERMISSIONS_NOTE = 'This audit reflects only structural access relationships (group/collection ' \
        'assignments and memberships); it does not account for the role permissions a user held at ' \
        'any time. It shows when a user may have had access (the relationship existed) and when they ' \
        'could not have had access (no relationship).'

      # Small fuzz used to evaluate effective access just-before / just-after an event timestamp.
      EVENT_EPSILON = 1.second

      CurrentAccess = Struct.new(:users, :paths) do
        def user_count
          users.size
        end

        def path_count
          paths.size
        end
      end

      # An effective-access window for a user, tagged with the path descriptor that granted it.
      Segment = Struct.new(:start_at, :end_at, :via, keyword_init: true)

      # One annotated row in the change log.
      Event = Struct.new(:version, :display_item, :affected_user, :effect, :path_label, keyword_init: true) do
        def occurred_at
          version.created_at
        end
      end

      attr_reader :cohort

      def initialize(cohort)
        @cohort = cohort
      end

      # { user_id => [Segment, ...] }, segments merged per user preserving the contributing paths.
      def effective_intervals
        @effective_intervals ||= build_effective_intervals
      end

      def current_access
        active = effective_intervals.transform_values { |segs| segs.select { |s| s.end_at.nil? } }
        active.reject! { |_, segs| segs.empty? }
        users = users_by_id.values_at(*active.keys).compact
        paths = active.values.flatten.flat_map(&:via).uniq
        CurrentAccess.new(users, paths)
      end

      # The annotated change log, newest first.
      def events
        @events ||= build_events
      end

      def to_csv
        require 'csv'
        CSV.generate do |csv|
          csv << ['# ' + PERMISSIONS_NOTE]
          csv << ['Changed At', 'Editor', 'Path', 'Affected User', 'Event', 'Effect', 'Changes']
          events.each do |event|
            csv << [
              event.occurred_at&.to_fs,
              editor_text(event),
              event.path_label,
              event.affected_user&.name,
              event.version.event.titleize,
              event.effect.to_s.titleize,
              Array(event.display_item&.changes).join('; '),
            ]
          end
        end
      end

      # ---- Subclass hooks -------------------------------------------------------------------------

      # Array of path objects (e.g. AccessGroups or Collections) that connect this cohort to users.
      def paths
        raise NotImplementedError
      end

      # [Interval] windows during which the cohort was viewable through +path+.
      def cohort_visible_intervals(_path)
        raise NotImplementedError
      end

      # { user_id => [Interval] } windows during which each user was a member reachable through +path+.
      def member_intervals(_path)
        raise NotImplementedError
      end

      # The PaperTrail versions (from either version class) that make up the raw change log.
      def raw_versions
        raise NotImplementedError
      end

      # The user ids affected by a given version at its instant (fans group-level events out to members).
      def affected_user_ids_for(_version)
        raise NotImplementedError
      end

      # A human label for the descriptor stored on a Segment's :via.
      def path_label(_descriptor)
        raise NotImplementedError
      end

      def model_label
        raise NotImplementedError
      end

      # The descriptor recorded on segments granted through +path+ (also used for path_label/grouping).
      def descriptor_for(_path)
        raise NotImplementedError
      end

      private

      def build_effective_intervals
        result = Hash.new { |hash, key| hash[key] = [] }
        paths.each do |path|
          visible = cohort_visible_intervals(path)
          next if visible.empty?

          descriptor = descriptor_for(path)
          member_intervals(path).each do |user_id, membership|
            Intervals.intersect(membership, visible).each do |window|
              result[user_id] << Segment.new(start_at: window.start_at, end_at: window.end_at, via: descriptor)
            end
          end
        end
        result
      end

      def build_events
        versions = raw_versions
        display_items = Audit::DisplayItem.build_batch(versions, users_by_id, ['updated_at'])
        display_by_version = versions.zip(display_items).to_h

        events = versions.flat_map do |version|
          affected_user_ids_for(version).map do |user_id|
            Event.new(
              version: version,
              display_item: display_by_version[version],
              affected_user: users_by_id[user_id],
              effect: effect_for(user_id, version.created_at),
              path_label: label_for_version(version),
            )
          end
        end
        events.sort_by { |event| [event.occurred_at, event.version.id.to_i] }.reverse
      end

      def effect_for(user_id, at_time)
        before = effective_at?(user_id, at_time - EVENT_EPSILON)
        after = effective_at?(user_id, at_time + EVENT_EPSILON)
        if !before && after
          :granted
        elsif before && !after
          :revoked
        else
          :no_effect
        end
      end

      def effective_at?(user_id, time)
        segments = effective_intervals[user_id]
        return false if segments.blank?

        segments.any? { |segment| Interval.new(segment.start_at, segment.end_at).covers?(time) }
      end

      # Default label hook for an individual version; subclasses may override for richer context.
      def label_for_version(_version)
        nil
      end

      def editor_text(event)
        item = event.display_item
        return 'System' unless item&.username

        item.impersonating ? "#{item.username} (Impersonating #{item.impersonating})" : item.username
      end

      def users_by_id
        @users_by_id ||= User.with_deleted.where(id: relevant_user_ids).index_by(&:id)
      end

      def relevant_user_ids
        ids = effective_intervals.keys
        ids += raw_versions.flat_map { |version| affected_user_ids_for(version) }
        ids.compact.uniq
      end
    end
  end
end
