###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class AmaRestriction < GrdaWarehouseBase
    include ::HealthEmergency

    scope :visible_to, -> (user) do
      return current_scope if user.can_see_health_emergency_clinical?

      none
    end

    scope :active, -> do
      where(restricted: 'Yes')
    end

    scope :added_within_range, -> (range=DateTime.current..DateTime.current) do
      # FIXME: unclear why, but because we get dates and compare to times, postgres gets very unhappy
      end_date = range.last + 2.days
      range = Time.zone.at(range.first.to_time)..Time.zone.at(end_date.to_time)
      where(created_at: range)
    end

    scope :unsent, -> do
      where(notification_at: nil)
    end

    def visible_to?(user)
      user.can_see_health_emergency_medical_restriction?
    end

    def self.next_batch_id
      current_batch = maximum(:notification_batch_id) || 0
      current_batch + 1
    end

    def sort_date
      updated_at
    end

    def in_batch?(batch_id)
      return false unless batch_id
      notification_batch_id == batch_id&.to_i
    end

    def title
      'Medical Restriction'
    end

    def pill_title
      'Medical'
    end

    def show_pill_in_search_results?
      restricted == 'Yes'
    end

    def restriction_options
      {
        'Yes' => 'Yes',
        'Cleared' => '',
      }
    end

    # Only show a status if one has been set
    def status
      return 'Restricted' if restricted == 'Yes'
      return 'Cleared' if restricted.blank?
    end
  end
end
