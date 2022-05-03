###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthIpFollowupReport
  class FollowupsReport
    def initialize(start_date:, end_date:)
      @range = (start_date..end_date)
    end

    def qas_by_month
      @qas_by_month ||= Health::QualifyingActivity.
        submittable.
        in_range(@range).
        where(activity: :discharge_follow_up).
        group(Arel.sql("DATE_TRUNC('MONTH', date_of_activity)")).
        count.
        transform_keys { |k| k.to_date.strftime('%Y-%m-%d') }
    end

    def visits_by_month
      @visits_by_month ||= Health::EdIpVisit.
        inpatient.
        in_range(@range).
        group(Arel.sql("DATE_TRUNC('MONTH', admit_date)")).
        count.
        transform_keys { |k| k.to_date.strftime('%Y-%m-%d') }
    end

    def dates
      (qas_by_month.keys + visits_by_month.keys).uniq
    end

    def infill(data)
      dates.map do |date|
        data[date] || 0
      end
    end

    def for_chart
      [
        ['x'] + dates,
        ['QAs'] + infill(qas_by_month),
        ['Admissions'] + infill(visits_by_month),
      ]
    end
  end
end
