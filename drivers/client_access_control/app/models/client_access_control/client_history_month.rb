###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl
  class ClientHistoryMonth
    include ArelHelper

    # Order here is used for display
    # left-to-right, top-to-bottom
    CONTACT_TYPES = {
      'bed_nights' => { name: 'Bed Night', icon: 'icon-moon-inv' },
      'service_dates' => { name: 'Service', icon: 'icon-clip-board-check' },
      'current_situations' => { name: 'Current Living Situation', icon: 'icon-download2' },
      'move_in_dates' => { name: 'Move-in Date', icon: 'icon-enter' },
      'extrapolation' => { name: 'Extrapolated', icon: 'icon-cross' },
      'ce_events' => { name: 'CE Event', icon: '' },
      'custom_events' => { name: 'Custom', icon: '' },
    }.freeze

    def initialize(year = Date.current.year, month = Date.current.month, filters = {})
      @year = year
      @month = month
      @filters = filters
      @date = Date.new(@year, @month, 1)
    end

    def title
      @date.strftime('%B %Y')
    end

    def filter_params(date)
      { month: date.month, year: date.year }
    end

    def previous_date(client)
      return @date - 1.month if min_date(client) <= @date - 1.month
    end

    def next_date
      return @date + 1.month if Date.today.end_of_month >= (@date + 1.month).end_of_month
    end

    def contact_types
      CONTACT_TYPES
    end

    def available_projects(month:, year:, client:, user:)
      @available_projects ||= ::GrdaWarehouse::Hud::Project.
        joins(service_history_enrollments: :enrollment).
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        merge(
          ::GrdaWarehouse::ServiceHistoryEnrollment.open_between(
            start_date: date_range_for(month: month, year: year).first,
            end_date: date_range_for(month: month, year: year).last,
          ).where(client_id: client.id),
        ).distinct.to_a.
        sort_by { |p| p.name(user) }
    end

    def available_project_types(month:, year:, client:, user:)
      project_types = available_projects(month: month, year: year, client: client, user: user).map(&:project_type_to_use)
      HudUtility2024.project_types.select { |k, _| k.in?(project_types) }
    end

    private def enrollments(month:, year:, client:, week:, user:)
      @enrollments ||= client.service_history_entries.
        joins(:enrollment).
        preload(:project).
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        open_between(
          start_date: date_range_for(month: month, year: year).first,
          end_date: date_range_for(month: month, year: year).last,
        ).to_a
      @enrollments.select do |en|
        en.entry_date < week.last && (en.exit_date.blank? || en.exit_date > week.first)
      end
    end

    private def services(month:, year:, client:, user:, she:, week:)
      @services ||= client.source_services.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        distinct.
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        where(date_provided: date_range_for(month: month, year: year)).
        to_a
      @services.select { |item| item.date_provided.in?(week) }.
        group_by { |item| item.enrollment.service_history_enrollment }[she] || []
    end

    private def max_bed_night(she)
      @max_bed_night ||= she.client.source_services.bed_night.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        maximum(:DateProvided)
      @max_bed_night[she.id]
    end

    private def bed_night_count(she)
      @bed_night_count ||= she.client.source_services.bed_night.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        count(:DateProvided)
      @bed_night_count[she.id]
    end

    private def max_service(she)
      @max_service ||= she.client.source_services.not_bed_night.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        maximum(:DateProvided)
      @max_service[she.id]
    end

    private def service_count(she)
      @service_count ||= she.client.source_services.not_bed_night.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        count(:DateProvided)
      @service_count[she.id] || {}
    end

    private def current_living_situations(month:, year:, client:, user:, she:, week:)
      @current_living_situations ||= client.source_current_living_situations.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        distinct.
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        where(InformationDate: date_range_for(month: month, year: year)).
        to_a

      @current_living_situations.select { |item| item.information_date.in?(week) }.
        group_by { |item| item.enrollment.service_history_enrollment }[she] || []
    end

    private def max_current_living_situation(she)
      @max_current_living_situation ||= she.client.source_current_living_situations.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        where(she_t[:client_id].eq(she.client_id)).
        group(she_t[:id]).
        maximum(:InformationDate)
      @max_current_living_situation[she.id]
    end

    private def current_living_situation_count(she)
      @current_living_situation_count ||= she.client.source_current_living_situations.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        where(she_t[:client_id].eq(she.client_id)).
        group(she_t[:id]).
        count(:InformationDate)
      @current_living_situation_count[she.id]
    end

    private def events(month:, year:, client:, user:, she:, week:)
      @events ||= client.source_events.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        where(EventDate: date_range_for(month: month, year: year)).
        distinct.
        to_a

      @events.select { |item| item.event_date.in?(week) }.
        group_by { |item| item.enrollment.service_history_enrollment }[she] || []
    end

    private def max_event(she)
      @max_event ||= she.client.source_events.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        maximum(:EventDate)
      @max_event[she.id]
    end

    private def event_count(she)
      @event_count ||= she.client.source_events.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        count(:EventDate)
      @event_count[she.id]
    end

    private def custom_services(month:, year:, client:, user:, she:, week:)
      @custom_services ||= client.source_custom_b_services.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        distinct.
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        where(date: date_range_for(month: month, year: year)).to_a

      @custom_services.select { |item| item.date.in?(week) }.
        group_by { |item| item.enrollment.service_history_enrollment }[she] || []
    end

    private def max_custom_service(she)
      @max_custom_service ||= she.client.source_custom_b_services.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        maximum(:date)
      @max_custom_service[she.id]
    end

    private def custom_service_count(she)
      @custom_service_count ||= she.client.source_custom_b_services.
        joins(enrollment: [:project, { service_history_enrollment: :client }]).
        references(enrollment: [:project, { service_history_enrollment: :client }]).
        group(she_t[:id]).
        count(:date)
      @custom_service_count[she.id]
    end

    # Return first and last date of extrapolation, if any overlap the week
    private def extrapolated(month:, year:, client:, week:, user:)
      @extrapolated ||= client.service_history_services.
        extrapolated.
        joins(service_history_enrollment: :enrollment).
        references(service_history_enrollment: :enrollment).
        merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)).
        service_within_date_range(
          start_date: date_range_for(month: month, year: year).first,
          end_date: date_range_for(month: month, year: year).last,
        ).to_a
      return [] unless @extrapolated.any? { |item| item.date.in?(week) }

      @extrapolated.group_by(&:service_history_enrollment)
    end

    private def date_range_for(month:, year:)
      Date.new(year, month, 1) .. Date.new(year, month, -1)
    end

    def min_date(client)
      ::GrdaWarehouse::ServiceHistoryEnrollment.entry.where(client_id: client.id).minimum(:entry_date) || Date.current
    end

    # The lesser of today or the max exit date
    def max_date(client)
      ::GrdaWarehouse::ServiceHistoryEnrollment.entry.
        where(client_id: client.id).
        pluck(cl(she_t[:last_date_in_program], Date.current)).
        max || Date.current
    end

    def add_project_for_week(projects:, project:, she:, user:)
      return projects unless project.present?

      project_type = project.project_type_to_use
      projects[she.id] ||= {
        project_id: project.id.to_s,
        project_name: project.name(user),
        project_type: project_type.to_s,
        project_type_name: HudUtility2024.project_type_brief(project_type),
        entry_date: she.entry_date,
        exit_date: she.exit_date.presence || Date.current,
      }
      projects
    end

    def weeks_data(month:, year:, client:, user:)
      @weeks_data ||= [].tap do |data|
        start_of_month = date_range_for(month: month, year: year).first
        # Ruby weeks start on Monday
        sunday = start_of_month.beginning_of_week - 1.days
        saturday = start_of_month.end_of_month.end_of_week - 1.days
        date_range = (sunday..saturday)
        date_range.each_slice(7) do |week|
          week_data = {
            month: month,
            days: week,
          }
          projects = {}
          enrollments(month: month, year: year, client: client, week: week, user: user).each do |she|
            project = she.project
            projects = add_project_for_week(projects: projects, project: project, she: she, user: user)
            if she.move_in_date.present?
              projects[she.id][:move_in_dates] ||= []
              projects[she.id][:move_in_dates] << she.move_in_date
            end

            # Services
            items = services(month: month, year: year, client: client, week: week, she: she, user: user)
            bed_nights = items.select(&:bed_night?)
            bed_night_dates = bed_nights.map(&:date_provided)
            max_date = max_bed_night(she)
            bed_night_dates << max_date unless bed_night_dates.include?(max_date)

            service_items = items.reject(&:bed_night?)
            service_dates = service_items.map(&:date_provided)
            max_date = max_service(she)
            service_dates << max_date unless service_dates.include?(max_date)

            if bed_nights.any?
              projects[she.id][:total_bed_nights] ||= bed_night_count(she)
              projects[she.id][:bed_nights] ||= bed_night_dates
            end
            if service_items.any?
              projects[she.id][:total_services] ||= service_count(she)
              projects[she.id][:service_dates] ||= service_dates
            end

            # Current Living Situations
            items = current_living_situations(month: month, year: year, client: client, week: week, she: she, user: user)
            item_dates = items.map(&:InformationDate)
            max_date = max_current_living_situation(she)
            item_dates << max_date unless item_dates.include?(max_date)
            if item_dates.any?
              projects[she.id][:total_current_situations] ||= current_living_situation_count(she)
              projects[she.id][:current_situations] ||= item_dates
            end

            # Events
            items = events(month: month, year: year, client: client, week: week, she: she, user: user)
            item_dates = items.map(&:EventDate)
            max_date = max_event(she)
            item_dates << max_date unless item_dates.include?(max_date)
            if item_dates.any?
              projects[she.id][:total_ce_events] ||= event_count(she)
              projects[she.id][:ce_events] ||= item_dates
            end

            # Custom Services
            items = custom_services(month: month, year: year, client: client, week: week, she: she, user: user)
            item_dates = items.map(&:date)
            item_names = items.map(&:service_name)
            max_date = max_custom_service(she)
            if item_dates.exclude?(max_date)
              item_dates << max_date
              item_names << 'Most Recent'
            end
            if item_dates.any? # rubocop:disable Style/Next
              projects[she.id][:total_custom_events] ||= custom_service_count(she)
              projects[she.id][:custom_events] ||= item_dates
              projects[she.id][:custom_events_names] ||= item_names
            end
          end

          # Extrapolated, note: this must be done outside of the project loop because the extrapolation
          # can extend onto weeks that are before entry or after exit
          extrapolated(month: month, year: year, client: client, week: week, user: user).each do |she, items|
            if items.any? # rubocop:disable Style/Next
              projects[she.id] ||= {}
              projects[she.id][:extrapolation] ||= {
                entry_date: items.min_by(&:date).date,
                exit_date: items.max_by(&:date).date,
              }
            end
          end

          projects = {} if week.first > Date.current
          week_data[:projects] = projects.values
          data << week_data
        end
      end
    end
  end
end
