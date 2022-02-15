###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Youth
  class Base < GrdaWarehouseBase
    include ArelHelper
    include YouthExport
    has_paper_trail
    acts_as_paranoid
    self.abstract_class = true

    scope :visible_by?, ->(user) do
      # users at your agency, plus your own user in case you have no agency.
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id) + [user.id]

      # if you can see all youth intakes, show them all
      if user.can_view_youth_intake? || user.can_edit_youth_intake?
        all
        # If you can see your agency's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        where(user_id: agency_user_ids)
      else
        none
      end
    end
  end
end
