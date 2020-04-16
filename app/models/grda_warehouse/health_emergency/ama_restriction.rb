###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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

    def visible_to?(user)
      user.can_see_health_emergency_medical_restriction?
    end

    def title
      'Medical Restriction'
    end

    def pill_title
      'Medical'
    end

    def show_pill_in_history?
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
      note_text = " (#{note})" if note.present?
      return "Restricted" if restricted == 'Yes'
      # return "No Restriction#{note_text}" if restricted == 'No'

      # 'Unknown'
    end
  end
end