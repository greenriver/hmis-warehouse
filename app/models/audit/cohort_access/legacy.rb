###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Audit
  module CohortAccess
    # TODO: START_ACL remove this whole file when the legacy permission model is removed.
    #
    # Cohort access audit for the LEGACY permission model:
    #   User -> AccessGroupMember -> AccessGroup -> GroupViewableEntity(access_group_id) -> Cohort
    # plus the personal access group special case, where the owning user has implicit membership
    # (no AccessGroupMember row).
    class Legacy < Base
      def model_label
        'Legacy (Access Groups)'
      end

      def paths
        @paths ||= AccessGroup.with_deleted.where(
          id: candidate_gves.map(&:access_group_id).uniq,
        ).to_a
      end

      def cohort_visible_intervals(group)
        rows = gves_by_group[group.id] || []
        intervals = rows.flat_map do |row|
          Intervals.reconstruct(gve_versions_by_item[row.id] || [], record: row)
        end
        Intervals.merge(intervals)
      end

      def member_intervals(group)
        result = {}
        (agms_by_group[group.id] || []).group_by(&:user_id).each do |user_id, rows|
          intervals = rows.flat_map do |row|
            Intervals.reconstruct(agm_versions_by_item[row.id] || [], record: row)
          end
          result[user_id] = Intervals.merge(intervals)
        end

        # Personal access group: the owning user is a member for the group's lifetime, with no
        # AccessGroupMember row to reconstruct. Derive that lifetime from the group's own versions
        # (AccessGroup has no created_at column, so reconstruct/fallback handles the timestamps).
        if group.user_id.present?
          owner_window = Intervals.reconstruct(access_group_versions_by_item[group.id] || [], record: group)
          result[group.user_id] = Intervals.merge((result[group.user_id] || []) + owner_window)
        end

        result
      end

      def descriptor_for(group)
        { model: :legacy, access_group_id: group.id }
      end

      def path_label(descriptor)
        group = paths_by_id[descriptor[:access_group_id]]
        return "Access Group ##{descriptor[:access_group_id]}" unless group

        group.user_id ? "Personal access group: #{group.name}" : "Access group: #{group.name}"
      end

      def raw_versions
        @raw_versions ||= gve_versions + agm_versions
      end

      def affected_user_ids_for(version)
        case version.item_type
        when 'AccessGroupMember'
          row = agms_by_id[version.item_id]
          row ? [row.user_id] : []
        when 'GrdaWarehouse::GroupViewableEntity'
          row = gves_by_id[version.item_id]
          group = row && paths_by_id[row.access_group_id]
          group ? members_active_at(group, version.created_at) : []
        else
          []
        end
      end

      private

      def label_for_version(version)
        group_id = case version.item_type
        when 'AccessGroupMember' then agms_by_id[version.item_id]&.access_group_id
        when 'GrdaWarehouse::GroupViewableEntity' then gves_by_id[version.item_id]&.access_group_id
        end
        group_id ? path_label(access_group_id: group_id) : nil
      end

      def members_active_at(group, time)
        member_intervals(group).select do |_user_id, intervals|
          Intervals.covers?(intervals, time)
        end.keys
      end

      def paths_by_id
        @paths_by_id ||= paths.index_by(&:id)
      end

      # All cohort GVEs that point at an access group (legacy side), before filtering to real groups.
      def candidate_gves
        @candidate_gves ||= cohort.group_viewable_entities.with_deleted.where.not(access_group_id: nil).to_a
      end

      # Only the GVEs that belong to a real, non-system access group we actually audit.
      def legacy_gves
        @legacy_gves ||= candidate_gves.select { |gve| paths_by_id.key?(gve.access_group_id) }
      end

      def gves_by_group
        @gves_by_group ||= legacy_gves.group_by(&:access_group_id)
      end

      def gves_by_id
        @gves_by_id ||= legacy_gves.index_by(&:id)
      end

      def gve_versions
        @gve_versions ||= GrdaWarehouse::Version.where(
          item_type: 'GrdaWarehouse::GroupViewableEntity',
          item_id: legacy_gves.map(&:id),
        ).to_a
      end

      def gve_versions_by_item
        @gve_versions_by_item ||= gve_versions.group_by(&:item_id)
      end

      def access_group_member_rows
        @access_group_member_rows ||= AccessGroupMember.with_deleted.where(
          access_group_id: legacy_gves.map(&:access_group_id).uniq,
        ).to_a
      end

      def agms_by_group
        @agms_by_group ||= access_group_member_rows.group_by(&:access_group_id)
      end

      def agms_by_id
        @agms_by_id ||= access_group_member_rows.index_by(&:id)
      end

      def agm_versions
        @agm_versions ||= GrPaperTrail::Version.where(
          item_type: 'AccessGroupMember',
          item_id: access_group_member_rows.map(&:id),
        ).to_a
      end

      def agm_versions_by_item
        @agm_versions_by_item ||= agm_versions.group_by(&:item_id)
      end

      # Used only to reconstruct a personal access group's lifetime (owner's implicit membership).
      def access_group_versions_by_item
        @access_group_versions_by_item ||= GrPaperTrail::Version.where(
          item_type: 'AccessGroup',
          item_id: paths.map(&:id),
        ).to_a.group_by(&:item_id)
      end
    end
  end
end
