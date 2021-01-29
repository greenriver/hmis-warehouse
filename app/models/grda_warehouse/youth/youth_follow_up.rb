###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Youth
  class YouthFollowUp < GrdaWarehouseBase
    include ArelHelper
    include YouthExport
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :youth_follow_ups
    belongs_to :user
    has_many :youth_intakes, through: :client
    belongs_to :case_managements, class_name: 'GrdaWarehouse::Youth::YouthCaseManagement', optional: true
    scope :ordered, -> do
      order(required_on: :desc)
    end

    scope :between, ->(start_date:, end_date:) do
      at = arel_table
      where(at[:contacted_on].gteq(start_date).and(at[:contacted_on].lteq(end_date)))
    end

    scope :incomplete, -> do
      where(contacted_on: nil)
    end

    scope :upcoming, -> do
      where(contacted_on: nil).
        where(arel_table[:required_on].between(Date.yesterday..1.weeks.from_now.to_date))
    end

    scope :due, -> do
      where(contacted_on: nil).
        where(arel_table[:required_on].lteq(Date.current))
    end

    scope :initial_action_at_risk, -> do
      where(action: :at_risk)
    end

    scope :initial_action_homeless, -> do
      where(action: :homeless)
    end

    scope :initial_action_housed, -> do
      where(action: :housed)
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

    def self.follow_up_date(action_date)
      action_date + 90.days
    end

    def housing_status_details
      if housing_status != 'No' && zip_code.present?
        "#{housing_status} (#{zip_code})"
      else
        housing_status
      end
    end

    def self.youth_housing_status_options
      [
        'No',
        'Yes, in RRH',
        'Yes, in market-rate housing',
        'Yes, in transitional housing',
        'Yes, with family',
      ]
    end
  end
end
