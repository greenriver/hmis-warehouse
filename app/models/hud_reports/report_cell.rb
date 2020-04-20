###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# A HUD report cell, identified by a question and cell name (e.g., question: 'Q1', cell_name: 'b2')
module HudReports
  class ReportCell < GrdaWarehouseBase
    self.table_name = 'hud_report_cells'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    has_many :universe_members

    def members
      @members ||= join_universe
    end

    def count
      @count ||= universe_members.count
    end

    def add_members(members)
      UniverseMember.import(
        members.map { |member| copy_member(member) },
      )
    end

    # Add members to the universe of this cell
    #
    # @param members [Hash<Client, ReportClientBase] the members to be associated with this cell
    def add_universe_members(members)
      UniverseMember.import(
        members.keys.map { |client| new_member(warehouse_client: client, universe_client: members[client]) },
      )
    end

    private def new_member(warehouse_client:, universe_client:)
      UniverseMember.new(
        report_cell: self,
        client: warehouse_client,
        first_name: warehouse_client.first_name,
        last_name: warehouse_client.last_name,
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
      none if count.zero?

      # joins don't work for polymorphic associations since it could join multiple tables.
      # However, for a given report cell, all of the universe members must be in the same table
      # and we can compute the name based on a single member.
      universe_table_name = universe_members.first.universe_membership.class.table_name

      universe_members.joins("JOIN #{universe_table_name} ON #{universe_table_name}.id = universe_membership_id")
    end
  end
end
