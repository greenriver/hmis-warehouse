###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientHistory::Calculator
  attr_accessor :client
  def initialize(client:)
    self.client = client
  end

  # If we haven't been in a literally homeless project type (ES, SH, SO) in the last 30 days, this is a new episode
  # You aren't currently housed in PH, and you've had at least a week of being housed in the last 90 days
  def new_episode?(enrollments:, enrollment:)
    return false unless HudUtility2024.chronic_project_types.include?(enrollment.project_type)

    entry_date = enrollment.entry_date
    thirty_days_ago = entry_date - 30.days
    ninety_days_ago = entry_date - 90.days

    housed_dates = residential_dates(enrollments: enrollments)
    currently_housed = housed_dates.include?(entry_date)
    housed_for_week_in_past_90_days = (housed_dates & (ninety_days_ago...entry_date).to_a).count > 7

    other_homeless = (homeless_dates(enrollments: enrollments) & (thirty_days_ago...entry_date).to_a).present?

    return true if ! currently_housed && housed_for_week_in_past_90_days && ! other_homeless

    return ! other_homeless
  end

  def residential_dates(enrollments:)
    @non_homeless_types ||= HudUtility2024.residential_project_type_numbers_by_code[:ph]
    @residential_dates ||= enrollments.select do |e|
      @non_homeless_types.include?(e.project_type)
    end.map do |e|
      # Use select to allow for preloading
      e.service_history_services.select do |s|
        s.homeless == false
      end.map(&:date)
    end.flatten.compact.uniq
  end

  private def homeless_dates(enrollments:)
    @homeless_dates ||= enrollments.select do |e|
      e.project_type.in?(HudUtility2024.residential_project_type_ids)
    end.map do |e|
      # Use select to allow for preloading
      e.service_history_services.select do |s|
        # Exclude extrapolated dates
        s.record_type == 'service' && s.homeless == true
      end.map(&:date)
    end.flatten.compact.uniq
  end
end
