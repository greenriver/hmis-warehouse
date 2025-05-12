###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientHistory::Calculator
  attr_accessor :client
  # @param client [Object] the client for whom calculations are performed
  def initialize(client:)
    self.client = client
  end

  # Determines if the enrollment in question is the start of a new episode of homelessness.
  # A new episode occurs if:
  #  - The client has not been in a literally homeless project (ES, SH, SO) in the last 30 days
  #  - The client is not currently housed in PH
  #  - The client was housed for at least a week in the past 90 days
  #
  # @param residential_enrollments [Array] a list of the client's residential enrollments
  # @param enrollment [Object] the specific enrollment being evaluated
  # @return [Boolean] true if the enrollment constitutes a new episode, otherwise false
  def new_episode?(residential_enrollments:, enrollment:)
    return false unless HudUtility2024.chronic_project_types.include?(enrollment.project_type)

    entry_date = enrollment.entry_date
    thirty_days_ago = entry_date - 30.days
    ninety_days_ago = entry_date - 90.days

    housed_dates = residential_dates(enrollments: residential_enrollments)
    currently_housed = housed_dates.include?(entry_date)
    housed_for_week_in_past_90_days = (housed_dates & (ninety_days_ago...entry_date).to_a).count > 7

    other_homeless = (homeless_dates(enrollments: residential_enrollments) & (thirty_days_ago...entry_date).to_a).present?

    return true if ! currently_housed && housed_for_week_in_past_90_days && ! other_homeless

    return ! other_homeless
  end

  # Returns the dates the client was housed in permanent housing.
  #
  # @param enrollments [Array] a list of enrollments related to the client
  # @return [Array<Date>] unique dates when the client was housed
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

  # Returns the dates the client was in a homeless project
  #
  # @param enrollments [Array] a list of enrollments related to the client
  # @return [Array<Date>] unique dates when the client was in a homeless project
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
