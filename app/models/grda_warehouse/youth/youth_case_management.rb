###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Youth
  class YouthCaseManagement < GrdaWarehouseBase
    include ArelHelper
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

    validates_presence_of :engaged_on, :activity

    scope :ordered, -> do
      order(engaged_on: :desc)
    end

    scope :between, -> (start_date:, end_date:) do
      at = arel_table
      where(at[:engaged_on].gteq(start_date).and(at[:engaged_on].lteq(end_date)))
    end

    scope :visible_by?, -> (user) do
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id)
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours, those for your agency, and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].in(agency_user_ids)).
          or(arel_table[:user_id].eq(user.id))
        )
      # If you can see your agancy's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        joins(:client).where(
          arel_table[:user_id].in(agency_user_ids).
          or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end


    def self.youth_housing_status_options
      [
          "This youth is currently in stable housing",
          "This youth is not currently in stable housing",
          "Unknown",
          "Other:",
      ]
    end

    def self.available_activities
      [
        'Prevention ',
        'Re-Housing',
      ]
    end
  end
end