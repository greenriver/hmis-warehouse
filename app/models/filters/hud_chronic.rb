###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HudChronic < ::ModelForm
    attribute :on, Date, default: ->(_r, _) { GrdaWarehouse::HudChronic.most_recent_day }
    attribute :min_age, Integer, default: 0
    attribute :individual, Boolean, default: false
    attribute :dmh, Boolean, default: false
    attribute :veteran, Boolean, default: false
    attribute :hoh, Boolean, default: false
    attribute :last_service_after, Integer, default: 30
    attribute :name, String

    def dates
      @dates ||= GrdaWarehouse::HudChronic.select(:date).distinct.order(date: :desc).pluck(:date)
    end

    def ages
      [0, 18, 24]
    end

    def date
      @date ||= begin
        if dates.include?(on)
          on
        else
          use = on
          dates.each do |d|
            if d < on
              use = d
              break
            end
          end
          use
        end
      end
    end

    def chronic_days
      dates
    end

    def date_ranges
      {
        '0 days before chronic date' => 0,
        '30 days before chronic date' => 30,
        '60 days before chronic date' => 60,
        '90 days before chronic date' => 90,
      }
    end
  end
end
