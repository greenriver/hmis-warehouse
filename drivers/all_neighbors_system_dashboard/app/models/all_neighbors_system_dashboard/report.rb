###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status

    include ViewConfiguration
    include SheetGenerator

    include EnrollmentAttributeCalculations
    include DemographicRatioCalculations

    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def run_and_save!
      start
      begin
        populate_universe
        calculate_results
      rescue Exception => e
        update(failed_at: Time.current)
        raise e
      end
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def url
      all_neighbors_system_dashboard_warehouse_reports_all_neighbors_system_dashboard_url(host: ENV.fetch('FQDN'), id: id, protocol: :https, format: :xlsx)
    end

    def a_t
      @a_t ||= Enrollment.arel_table
    end

    def populate_universe
      enrollment_scope.find_in_batches do |batch|
        enrollments = {}
        batch.each do |enrollment|
          source_enrollment = enrollment.enrollment
          ce_info = ce_info(filter, enrollment)
          enrollments[enrollment.id] = Enrollment.new(
            report_id: id,
            household_id: enrollment.household_id,
            household_type: household_type(enrollment),
            prior_living_situation_category: prior_living_situation_category(source_enrollment),
            enrollment_id: source_enrollment.enrollment_id,
            entry_date: enrollment.first_date_in_program,
            move_in_date: enrollment.move_in_date,
            exit_date: exit_date(filter, enrollment),
            adjusted_exit_date: adjusted_exit_date(filter, enrollment),
            exit_type: exit_type(enrollment),
            destination: enrollment.destination,
            destination_text: HudUtility.destination(enrollment.destination),
            relationship: relationship(source_enrollment),
            client_id: source_enrollment.personal_id,
            age: enrollment.age,
            gender: gender(enrollment),
            primary_race: primary_race(enrollment),
            race_list: enrollment.client.race_description(include_missing_reason: true),
            ethnicity: HudUtility.ethnicity(enrollment.client.ethnicity),
            ce_entry_date: ce_info&.entry_date,
            ce_referral_date: ce_info&.ce_event&.event_date,
            ce_referral_id: ce_info&.ce_event&.event_id,
            return_date: return_date(filter, enrollment),
            project_id: source_enrollment.project_id,
            project_name: enrollment.project.name, # get from project directly to handle project confidentiality
            project_type: enrollment.project_type,
          )
        end
        Enrollment.import!(enrollments.values)
        universe.add_universe_members(enrollments)
      end

      # Attach the CE Events to the first report enrollment (requires at least one enrollment)
      enrollment = universe.members.first.universe_membership
      event_scope.find_in_batches do |batch|
        events = []
        batch.each do |event|
          events << enrollment.events.build(
            event_id: event.event_id,
            event_date: event.event_date,
            event: HudUtility.event(event.event),
            location: event.location_crisis_or_ph_housing,
            project_name: event.enrollment.project.name,
            project_type: event.enrollment.project.project_type,
            referral_result: event.referral_result,
            result_date: event.result_date,
          )
        end
        Event.import!(events)
      end
    end

    def calculate_results
      save_project_ratios
      save_system_ratios
    end

    def enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: filter.start_date, end_date: filter.end_date)
      filter.apply(scope)
    end

    def event_scope
      GrdaWarehouse::Hud::Event.
        within_range(filter.range).
        where(Event: SERVICE_CODE_ID.keys)
    end
  end
end
