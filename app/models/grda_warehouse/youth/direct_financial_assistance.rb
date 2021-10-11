###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Youth
  class DirectFinancialAssistance < GrdaWarehouseBase
    include ArelHelper
    include YouthExport
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :direct_financial_assistances, optional: true
    belongs_to :user, optional: true
    has_many :youth_intakes, through: :client
    validates_presence_of :provided_on, :type_provided

    attr_accessor :other

    scope :ordered, -> do
      order(provided_on: :desc)
    end

    scope :between, ->(start_date:, end_date:) do
      at = arel_table
      where(at[:provided_on].gteq(start_date).and(at[:provided_on].lteq(end_date)))
    end

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

    def report_types
      @report_types ||= [
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
      ]
    end

    def available_types
      @available_types ||= [
        'Move-in costs',
        'Moving expenses',
        'Rent',
        'Rent arrears',
        'Utilities',
        'Emergency Shelter Night Owl Stay',
        'Emergency Shelter Hotel',
        'Transportation-related costs',
        'Transportation/relocation assistance',
        'Education-related costs',
        'Legal costs',
        'Child care',
        'Work-related costs',
        'Medical costs',
        'Cell phone costs',
        'Food / Groceries (including our drop-in food pantries)',
        'Deposits',
        'Car repairs',
        'Securing IDs',
        'Background checks',
        'Furniture assistance for alternate housing',
        'Pet boarding',
      ].sort + ['Other']
    end
  end
end
