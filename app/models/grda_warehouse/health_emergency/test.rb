###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Test < GrdaWarehouseBase
    include ::HealthEmergency

    validates_presence_of :tested_on, :result, on: :create
    scope :visible_to, -> (user) do
      return current_scope if user.can_see_health_emergency_clinical?

      none
    end

    scope :tested_within_range, -> (range=Date.current..Date.current) do
      where(tested_on: range)
    end

    scope :unsent, -> do
      where(notification_at: nil)
    end

    def visible_to?(user)
      user.can_see_health_emergency_clinical?
    end

    def self.next_batch_id
      current_batch = maximum(:notification_batch_id) || 0
      current_batch + 1
    end

    def sort_date
      tested_on || updated_at
    end

    def location_options
      self.class.distinct.
        where.not(location: [nil, '']).
        order(:location).
        pluck(:location)
    end

    def in_batch?(batch_id)
      return false unless batch_id
      notification_batch_id == batch_id&.to_i
    end

    def title
      'Testing Results'
    end

    def pill_title
      'Test'
    end

    def result_options
      {
        'Positive' => 'Positive',
        'Negative' => 'Negative',
      }
    end

    def status
      return 'Unknown' if tested_on.blank?
      return 'Positive' if result == 'Positive'
      return 'Negative' if result == 'Negative'
      return 'Tested' if tested_on.present?

      'Unknown'
    end
  end
end
