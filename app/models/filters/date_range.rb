# provides validation for date ranges
module Filters
  class DateRange < ::ModelForm
    attribute :start, Date, lazy: true, default: -> (r,_) { r.default_start }
    attribute :end, Date, lazy: true, default: -> (r,_) { r.default_end }

    validates_presence_of :start, :end

    validate do
      if start > self.end
        errors.add(:end, 'End date must follow start date.')
      end
    end

    def range
      self.start .. self.end
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
      Date.today
    end

    class MonthDefault < DateRange
      def default_start
        self.end - 1.month
      end
    end
  end
end
