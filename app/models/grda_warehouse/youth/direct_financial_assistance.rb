###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Youth
  class DirectFinancialAssistance < GrdaWarehouseBase
    include ArelHelper
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :direct_financial_assistances
    validates_presence_of :provided_on, :type_provided

    attr_accessor :other

    scope :ordered, -> do
      order(provided_on: :desc)
    end

    scope :between, -> (start_date:, end_date:) do
      at = arel_table
      where(at[:provided_on].gteq(start_date).and(at[:provided_on].lteq(end_date)))
    end

    scope :visible_by?, -> (user) do
      # users at your agency, plus your own user in case you have no agency.
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id) + [user.id]
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours, those for your agency, and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        where(
          arel_table[:client_id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].in(agency_user_ids))
        )
      # If you can see your agency's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        where(user_id: agency_user_ids)
      else
        none
      end
    end


    def available_types
      @available_types ||= [
        'Move-in costs',
        'Rent',
        'Rent arrears',
        'Utilities',
        'Emergency Shelter Night Owl Stay',
        'Emergency Shelter Hotel',
        'Transportation-related costs',
        'Education-related costs',
        'Legal costs',
        'Child care',
        'Work-related costs',
        'Medical costs',
        'Cell phone costs',
        'Food / Groceries (including our drop-in food pantries)',
      ].sort + ['Other']
    end
  end
end