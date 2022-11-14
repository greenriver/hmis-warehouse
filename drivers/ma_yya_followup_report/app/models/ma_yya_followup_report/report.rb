###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaFollowupReport
  class Report
    include ArelHelper
    include Filter::FilterScopes

    attr_accessor :start_date, :late_date, :filter

    def initialize(filter)
      @filter = filter
      filter.require_service_during_range = false
      @end_date = filter.on
      @late_date = @end_date - 3.months
      @start_date = @late_date + 1.weeks
    end

    def clients
      return [] unless filter.project_ids.any? || filter.age_ranges.any?

      client_scope.pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.
        sort_by { |row| row[:last_seen] || row[:engagement_date] }
    end

    def columns
      window = ::Arel::Nodes::Window.new.partition(c_t[:id])
      {
        id: :id,
        first_name: :FirstName,
        last_name: :LastName,
        engagement_date: she_t[:first_date_in_program].minimum.over(window),
        last_seen: cls_t[:InformationDate].maximum.over(window),
      }
    end

    private def client_scope
      client_with_enrollment_scope.
        left_outer_joins(service_history_enrollments: [enrollment: :current_living_situations]).
        where.not(id: client_with_contact_scope.select(:id))
    end

    private def client_with_enrollment_scope
      ::GrdaWarehouse::Hud::Client.
        distinct.
        joins(:service_history_enrollments).
        merge(enrollment_scope)
    end

    private def client_with_contact_scope
      ::GrdaWarehouse::Hud::Client.
        distinct.
        joins(service_history_enrollments: [enrollment: :current_living_situations]).
        merge(enrollment_scope).
        merge(contact_scope)
    end

    private def enrollment_scope
      scope = ::GrdaWarehouse::ServiceHistoryEnrollment.entry
      scope = filter_for_range(scope)
      scope = filter_for_projects(scope)
      filter_for_age(scope)
    end

    private def contact_scope
      ::GrdaWarehouse::Hud::CurrentLivingSituation.
        between(start_date: @start_date, end_date: @end_date)
    end

    def yya_projects(user)
      filter.project_options_for_select(user: user)
    end

    def available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
      }.freeze
    end
  end
end
