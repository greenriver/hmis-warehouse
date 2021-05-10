###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimpleReports
  class ReportCell < GrdaWarehouseBase
    acts_as_paranoid

    self.table_name = 'simple_report_cells'

    belongs_to :report_instance, class_name: 'SimpleReports::ReportInstance'
    has_many :universe_members

    scope :universe, -> do
      where(universe: true)
    end

    def user
      report_instance.user
    end

    def members
      @members ||= join_universe
    end

    def count
      @count ||= universe_members.count
    end

    def add_members(members)
      UniverseMember.import(
        members.map { |member| copy_member(member) },
        validate: false,
        on_duplicate_key_ignore: true,
      )
    end

    private def new_member(warehouse_client:, universe_client:)
      UniverseMember.new(
        report_cell: self,
        client_id: warehouse_client.id,
        first_name: universe_client.first_name,
        last_name: universe_client.last_name,
        universe_membership: universe_client,
      )
    end

    private def copy_member(member)
      UniverseMember.new(
        report_cell: self,
        client_id: member.client_id,
        first_name: member.first_name,
        last_name: member.last_name,
        universe_membership_type: member.universe_membership_type,
        universe_membership_id: member.universe_membership_id,
      )
    end

    private def join_universe
      return self.class.none if count.zero?

      # joins don't work for polymorphic associations since it could join multiple tables.
      # However, for a given report cell, all of the universe members must be in the same table
      # and we can compute the name based on a single member.
      universe_table_name = universe_members.first.universe_membership.class.arel_table
      members_table = universe_members.arel_table

      table_join = members_table.join(universe_table_name).on(members_table[:universe_membership_id].eq(universe_table_name[:id]))
      universe_members.joins(table_join.join_sources)
    end
  end
end
