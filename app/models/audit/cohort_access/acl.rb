###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Audit
  module CohortAccess
    # Cohort access audit for the ACL permission model:
    #   User -> UserGroupMember -> UserGroup -> AccessControl(collection_id) -> Collection
    #        -> GroupViewableEntity(collection_id) -> Cohort
    #
    # Effective access requires all three structural relationships to overlap: the cohort viewable in
    # the collection, an access control tying a user group to that collection, and the user being a
    # member of that user group. The access control's Role is intentionally ignored (see Base).
    class Acl < Base
      def model_label
        'ACL (Collections)'
      end

      def paths
        @paths ||= Collection.with_deleted.where(
          id: candidate_gves.map(&:collection_id).uniq,
        ).to_a
      end

      def cohort_visible_intervals(collection)
        rows = gves_by_collection[collection.id] || []
        intervals = rows.flat_map do |row|
          Intervals.reconstruct(gve_versions_by_item[row.id] || [], record: row)
        end
        Intervals.merge(intervals)
      end

      def member_intervals(collection)
        result = Hash.new { |hash, key| hash[key] = [] }
        (access_controls_by_collection[collection.id] || []).each do |access_control|
          control_active = Intervals.reconstruct(ac_versions_by_item[access_control.id] || [], record: access_control)
          (ugms_by_group[access_control.user_group_id] || []).group_by(&:user_id).each do |user_id, rows|
            membership = Intervals.merge(rows.flat_map do |row|
              Intervals.reconstruct(ugm_versions_by_item[row.id] || [], record: row)
            end)
            result[user_id].concat(Intervals.intersect(membership, control_active))
          end
        end
        result.transform_values { |intervals| Intervals.merge(intervals) }
      end

      def descriptor_for(collection)
        { model: :acl, collection_id: collection.id }
      end

      def path_label(descriptor)
        collection = paths_by_id[descriptor[:collection_id]]
        collection ? "Collection: #{collection.name}" : "Collection ##{descriptor[:collection_id]}"
      end

      def raw_versions
        @raw_versions ||= gve_versions + access_control_versions + ugm_versions
      end

      def affected_user_ids_for(version)
        case version.item_type
        when 'UserGroupMember'
          row = ugms_by_id[version.item_id]
          row ? [row.user_id] : []
        when 'AccessControl'
          access_control = acs_by_id[version.item_id]
          access_control ? members_of_user_group_at(access_control.user_group_id, version.created_at) : []
        when 'GrdaWarehouse::GroupViewableEntity'
          row = gves_by_id[version.item_id]
          collection = row && paths_by_id[row.collection_id]
          collection ? members_active_at(collection, version.created_at) : []
        else
          []
        end
      end

      private

      def label_for_version(version)
        collection_id = case version.item_type
        when 'GrdaWarehouse::GroupViewableEntity'
          gves_by_id[version.item_id]&.collection_id
        when 'AccessControl'
          acs_by_id[version.item_id]&.collection_id
        when 'UserGroupMember'
          user_group_id = ugms_by_id[version.item_id]&.user_group_id
          acs_by_user_group[user_group_id]&.first&.collection_id
        end
        collection_id ? path_label(collection_id: collection_id) : nil
      end

      def members_active_at(collection, time)
        member_intervals(collection).select do |_user_id, intervals|
          Intervals.covers?(intervals, time)
        end.keys
      end

      def members_of_user_group_at(user_group_id, time)
        (ugms_by_group[user_group_id] || []).group_by(&:user_id).select do |_user_id, rows|
          intervals = Intervals.merge(rows.flat_map do |row|
            Intervals.reconstruct(ugm_versions_by_item[row.id] || [], record: row)
          end)
          Intervals.covers?(intervals, time)
        end.keys
      end

      def paths_by_id
        @paths_by_id ||= paths.index_by(&:id)
      end

      def candidate_gves
        @candidate_gves ||= cohort.group_viewable_entities.with_deleted.where.not(collection_id: nil).to_a
      end

      def acl_gves
        @acl_gves ||= candidate_gves.select { |gve| paths_by_id.key?(gve.collection_id) }
      end

      def gves_by_collection
        @gves_by_collection ||= acl_gves.group_by(&:collection_id)
      end

      def gves_by_id
        @gves_by_id ||= acl_gves.index_by(&:id)
      end

      def gve_versions
        @gve_versions ||= GrdaWarehouse::Version.where(
          item_type: 'GrdaWarehouse::GroupViewableEntity',
          item_id: acl_gves.map(&:id),
        ).to_a
      end

      def gve_versions_by_item
        @gve_versions_by_item ||= gve_versions.group_by(&:item_id)
      end

      def access_control_rows
        @access_control_rows ||= AccessControl.with_deleted.where(collection_id: paths.map(&:id)).to_a
      end

      def access_controls_by_collection
        @access_controls_by_collection ||= access_control_rows.group_by(&:collection_id)
      end

      def acs_by_id
        @acs_by_id ||= access_control_rows.index_by(&:id)
      end

      def acs_by_user_group
        @acs_by_user_group ||= access_control_rows.group_by(&:user_group_id)
      end

      def access_control_versions
        @access_control_versions ||= GrPaperTrail::Version.where(
          item_type: 'AccessControl',
          item_id: access_control_rows.map(&:id),
        ).to_a
      end

      def ac_versions_by_item
        @ac_versions_by_item ||= access_control_versions.group_by(&:item_id)
      end

      def user_group_member_rows
        @user_group_member_rows ||= UserGroupMember.with_deleted.where(
          user_group_id: access_control_rows.map(&:user_group_id).uniq,
        ).to_a
      end

      def ugms_by_group
        @ugms_by_group ||= user_group_member_rows.group_by(&:user_group_id)
      end

      def ugms_by_id
        @ugms_by_id ||= user_group_member_rows.index_by(&:id)
      end

      def ugm_versions
        @ugm_versions ||= GrPaperTrail::Version.where(
          item_type: 'UserGroupMember',
          item_id: user_group_member_rows.map(&:id),
        ).to_a
      end

      def ugm_versions_by_item
        @ugm_versions_by_item ||= ugm_versions.group_by(&:item_id)
      end
    end
  end
end
