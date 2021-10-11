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

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :youth_follow_ups, optional: true
    belongs_to :user, optional: true
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

    scope :due, ->(date = Date.current) do
      where(contacted_on: nil).
        where(arel_table[:required_on].lteq(date))
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

    # Recreate the follow ups for clients within an optional range
    #
    # @param client_ids if present, only recreate the follow ups for the specified clients
    # @param start_date if present, don't replace follow ups before the specified date
    # @param end_date if present, don't replace follow ups after the specified date, defaults to the current date
    def self.recreate_follow_ups(client_ids: nil, start_date: Date.current - 90.days, end_date: Date.current)
      clients = GrdaWarehouse::Hud::Client.
        joins(:youth_intakes)
      clients = clients.where(id: client_ids) if client_ids.present?
      return unless clients.exists?

      clients.preload(:youth_intakes, :case_managements).each do |client|
        # Order the client's intakes and CM notes by date
        events = (client.youth_intakes.open_between(start_date: start_date, end_date: end_date) +
          client.case_managements.between(start_date: start_date, end_date: end_date)).sort_by do |item|
          [
            event_date(item),
            (item.is_a?(GrdaWarehouse::YouthIntake::Base) ? 1 : 2), # If there is more than entry on the same date, process intakes first
          ]
        end
        next if events.blank?

        transaction do
          # Remove the old follow ups in the range
          client.youth_follow_ups.between(start_date: start_date, end_date: end_date).destroy_all

          # Create new follow ups by processing events in ascending order
          events.each do |event|
            event.create_required_follow_up!

            next if event.is_a?(GrdaWarehouse::YouthIntake::Base)

            event.complete_required_follow_up!
          end
        end
      end
    end

    def self.event_date(event)
      (event.is_a?(GrdaWarehouse::YouthIntake::Base) && event.engagement_date) || event.engaged_on
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
