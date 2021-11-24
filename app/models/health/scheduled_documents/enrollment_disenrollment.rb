###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ScheduledDocuments::EnrollmentDisenrollment < Health::ScheduledDocuments::Base
    validates :acos, presence: true

    def deliver(_user)
      # TODO
    end

    SUNDAY = 0
    SATURDAY = 6

    def should_be_delivered?
      # Determine when this document should be scheduled for this month
      delivery_date = Date.new(Date.current.year, Date.current.month, scheduled_day)
      delivery_date = delivery_date.yesterday if delivery_date.wday == SATURDAY
      delivery_date = delivery_date.tomorrow if delivery_date.wday == SUNDAY

      # See if today is the delivery date, and it hasn't already been run
      Date.current == delivery_date && (last_run_at.blank? || last_run_at.to_date < Date.current)
    end

    def params
      [
        :scheduled_day,
        acos: [],
      ]
    end
  end
end
