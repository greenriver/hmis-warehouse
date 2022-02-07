###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class DateRange < ::ModelForm
    attribute :start, Date, lazy: true, default: ->(r, _) { r.default_start }
    attribute :end, Date, lazy: true, default: ->(r, _) { r.default_end }
    attribute :sort
    attribute :age_ranges, Array, default: []
    attribute :heads_of_household, Boolean, default: false
    attribute :activity_type, Array, default: []
    attribute :agency_id, Integer
    attribute :user_id, Integer

    validates_presence_of :start, :end

    validate do
      errors.add(:end, 'End date must follow start date.') if start > self.end
    end

    def range
      self.start .. self.end # rubocop:disable Style/RedundantSelf
    end

    def first
      range.begin
    end

    # fifteenth of relevant month
    def ides
      first + 14.days
    end

    def last
      range.end
    end

    def default_start
      self.end - 1.week
    end

    def default_end
      Date.current
    end

    def length
      (self.end - self.start).to_i # rubocop:disable Style/RedundantSelf
    rescue StandardError
      0
    end

    class MonthDefault < DateRange
      def default_start
        self.end - 1.month
      end
    end

    def available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_sixty_one: '25 - 61',
        over_sixty_one: '62+',
      }.invert.freeze
    end
  end
end
