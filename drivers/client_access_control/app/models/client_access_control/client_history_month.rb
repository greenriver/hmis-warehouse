class ClientAccessControl::ClientHistoryMonth
  include ArelHelper

  CONTACT_TYPES = {
    'current_situations' => { name: 'Current Living Situation', icon: 'icon-download2' },
    'move_in_dates' => { name: 'Move-in Date', icon: 'icon-enter' },
    'extrapolation' => { name: 'Extrapolated', icon: 'icon-cross' },
    'bed_nights' => { name: 'Bed Night', icon: 'icon-moon-inv' },
    'service_dates' => { name: 'Service', icon: 'icon-clip-board-check' },
    'ce_events' => { name: 'CE Event', icon: '' },
    'custom_events' => { name: 'Custom', icon: '' },
  }.freeze

  def initialize(year, month, filters)
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

  def previous_date
    return @date - 1.month if first_date <= @date - 1.month
  end

  def next_date
    return @date + 1.month if Date.today.end_of_month >= (@date + 1.month).end_of_month
  end

  def first_date
    Date.new(2022, 1, 1)
  end

  def contact_types
    CONTACT_TYPES
  end

  def fake_project(date_range)
    project_names = ('A'..'Z').to_a
    project_index = rand(0..project_names.size - 1)
    entry_date_index = rand(0..date_range.size - 1)
    exit_date_index = rand(entry_date_index..date_range.size - 1)
    {
      project_name: "Project #{project_names[project_index]}",
      project_id: project_index.to_s,
      project_type: (project_index > 13 ? project_index % 13 : project_index + 1).to_s,
      entry_date: date_range[entry_date_index].strftime('%Y-%m-%d'),
      exit_date: date_range[exit_date_index].strftime('%Y-%m-%d'),
      current_situations: [
        date_range[entry_date_index].strftime('%Y-%m-%d'),
      ],
    }
  end

  def fake_data
    end_date = Date.new(2023, 7, 1)
    months = (first_date..end_date.end_of_month).to_a
    months.map do |month|
      end_of_week = month.end_of_month.end_of_week(:sunday)
      date = month.beginning_of_week(:sunday)
      weeks = []
      while date <= end_of_week
        weeks.push(date)
        date += 1.day
      end
      month_weeks = weeks.in_groups_of(7)
      month_data = {
        month: month.month,
        year: month.year,
        weeks: [],
      }
      month_weeks.map do |mw|
        month_data[:weeks].push(
          {
            year: month.year,
            month: month.month,
            days: mw.map { |n| n.strftime('%Y-%m-%d') },
            projects: Array.new(5).map do |_|
              fake_project(mw)
            end,
          },
        )
      end
      month_data
    end
  end

  # Return first and last date of extrapolation, if any overlap the week
  private def extrapolated(month:, year:, client:, week:)
    @extrapolated ||= GrdaWarehouse::ServiceHistoryService.
      extrapolated.
      joins(service_history_enrollment: :project).
      references(service_history_enrollment: :project).
      service_within_date_range(
        start_date: date_range_for(month: month, year: year).first,
        end_date: date_range_for(month: month, year: year).last,
      ).where(client_id: client.id).to_a
    return [] unless @extrapolated.any? { |item| item.date.in?(week) }

    @extrapolated
  end

  private def enrollments(month:, year:, client:, week:)
    @enrollments ||= GrdaWarehouse::ServiceHistoryEnrollment.entry.
      joins(:project).
      open_between(
        start_date: date_range_for(month: month, year: year).first,
        end_date: date_range_for(month: month, year: year).last,
      ).
      where(she_t[:client_id].eq(client.id)).to_a
    @enrollments.select do |en|
      en.entry_date < week.last && (en.exit_date.blank? || en.exit_date > week.first)
    end
  end

  private def services(month:, year:, client:, week:)
    @services ||= GrdaWarehouse::Hud::Service.
      joins(enrollment: [:project, { service_history_enrollment: :client }]).
      references(enrollment: [:project, { service_history_enrollment: :client }]).
      where(date_provided: date_range_for(month: month, year: year)).
      where(she_t[:client_id].eq(client.id)).to_a
    @services.select { |item| item.date_provided.in?(week) }
  end

  private def current_living_situations(month:, year:, client:, week:)
    @current_living_situations ||= GrdaWarehouse::Hud::CurrentLivingSituation.
      joins(enrollment: [:project, { service_history_enrollment: :client }]).
      references(enrollment: [:project, { service_history_enrollment: :client }]).
      where(InformationDate: date_range_for(month: month, year: year)).
      where(she_t[:client_id].eq(client.id)).to_a
    @current_living_situations.select { |item| item.information_date.in?(week) }
  end

  private def events(month:, year:, client:, week:)
    @events ||= GrdaWarehouse::Hud::Event.
      joins(enrollment: [:project, { service_history_enrollment: :client }]).
      references(enrollment: [:project, { service_history_enrollment: :client }]).
      where(EventDate: date_range_for(month: month, year: year)).
      where(she_t[:client_id].eq(client.id)).to_a
    @events.select { |item| item.event_date.in?(week) }
  end

  private def custom_services(month:, year:, client:, week:)
    @custom_services ||= client.source_custom_b_services.
      joins(enrollment: [:project, { service_history_enrollment: :client }]).
      where(date: date_range_for(month: month, year: year)).to_a
    @custom_services.select { |item| item.date.in?(week) }
  end

  private def date_range_for(month:, year:)
    Date.new(year, month, 1) .. Date.new(year, month, -1)
  end

  private def min_date(client)
    GrdaWarehouse::ServiceHistoryServiceMaterialized.where(client_id: client.id).minimum(:date)
  end

  private def max_date(client)
    GrdaWarehouse::ServiceHistoryServiceMaterialized.where(client_id: client.id).maximum(:date)
  end

  def weeks_data(month:, year:, client:, user:)
    @weeks_data ||= [].tap do |data|
      start_of_month = date_range_for(month: month, year: year).first
      date_range = (start_of_month.beginning_of_week..start_of_month.end_of_month.end_of_week)
      date_range.each_slice(7) do |week|
        week_data = {
          month: month,
          days: week,
        }
        projects = {}
        enrollments(month: month, year: year, client: client, week: week).each do |she|
          project = she.project
          project_type = project.project_type_to_use
          projects[she.id] ||= {
            project_name: project.name(user),
            project_type: project_type,
            project_type_name: HudUtility.project_type_brief(project_type),
            entry_date: she.entry_date,
            exit_date: she.exit_date,
          }
        end

        services(month: month, year: year, client: client, week: week).each do |service|
          she = service.enrollment.service_history_enrollment
          project = service.enrollment.project
          project_type = project.project_type_to_use
          projects[she.id] ||= {
            project_name: project.name(user),
            project_type: project_type,
            project_type_name: HudUtility.project_type_brief(project_type),
            entry_date: she.entry_date,
            exit_date: she.exit_date,
          }
          if service.bed_night?
            projects[she.id][:bed_nights] ||= []
            projects[she.id][:bed_nights] << service.date_provided
          else
            projects[she.id][:services] ||= []
            projects[she.id][:services] << service.date_provided
          end
        end

        extrapolated_by_enrollment = extrapolated(month: month, year: year, client: client, week: week).
          group_by(&:service_history_enrollment)

        extrapolated_by_enrollment.each do |she, services|
          project = she.project

          project_type = project.project_type_to_use

          projects[she.id] ||= {
            project_name: project.name(user),
            project_type: project_type,
            project_type_name: HudUtility.project_type_brief(project_type),
            entry_date: she.entry_date,
            exit_date: she.exit_date,
          }
          projects[she.id][:extrapolation] ||= {
            entry_date: services.min_by(&:date).date,
            exit_date: services.max_by(&:date).date,
          }
        end

        current_living_situations(month: month, year: year, client: client, week: week).each do |cls|
          she = cls.enrollment.service_history_enrollment
          project = cls.enrollment.project
          project_type = project.project_type_to_use
          projects[she.id] ||= {
            project_name: project.name(user),
            project_type: project_type,
            project_type_name: HudUtility.project_type_brief(project_type),
            entry_date: she.entry_date,
            exit_date: she.exit_date,
          }
          projects[she.id][:current_situations] ||= []
          projects[she.id][:current_situations] << cls.information_date
        end

        events(month: month, year: year, client: client, week: week).each do |event|
          she = event.enrollment.service_history_enrollment
          project = event.enrollment.project
          project_type = project.project_type_to_use
          projects[she.id] ||= {
            project_name: project.name(user),
            project_type: project_type,
            project_type_name: HudUtility.project_type_brief(project_type),
            entry_date: she.entry_date,
            exit_date: she.exit_date,
          }
          projects[she.id][:events] ||= []
          projects[she.id][:events] << event.event_date
        end

        custom_services(month: month, year: year, client: client, week: week).each do |service|
          she = service.enrollment.service_history_enrollment
          project = service.enrollment.project
          project_type = project.project_type_to_use
          projects[she.id] ||= {
            project_name: project.name(user),
            project_type: project_type,
            project_type_name: HudUtility.project_type_brief(project_type),
            entry_date: she.entry_date,
            exit_date: she.exit_date,
          }
          projects[she.id][:custom_events] ||= []
          projects[she.id][:custom_events] << service.date
          projects[she.id][:custom_events_names] ||= []
          projects[she.id][:custom_events_names] << service.service_name
        end

        week_data[:projects] = projects.values
        data << week_data
      end
    end

    # Example data:
    # if @month == 2 && @year == 2023
    #   [
    #     {
    #       month: 2,
    #       days: ['2023-01-29', '2023-01-30', '2023-01-31', '2023-02-01', '2023-02-02', '2023-02-03', '2023-02-04'],
    #       projects: [
    #         {
    #           project_name: 'Project A',
    #           entry_date: '2023-01-15',
    #           exit_date: '2023-02-10',
    #           project_type: 1,
    #           project_type_name: HudUtility.project_type_brief(1),
    #           bed_nights: [
    #             '2023-01-29',
    #             '2023-02-01',
    #             '2023-02-02',
    #           ],
    #           current_situations: [
    #             '2023-01-29',
    #           ],
    #           move_in_dates: [
    #             '2023-01-29',
    #           ],
    #           service_dates: [
    #             '2023-01-29',
    #           ],
    #           ce_events: [
    #             '2023-01-29',
    #           ],
    #           custom_events: [
    #             '2023-01-29',
    #             '2023-02-02',
    #             '2023-02-02',
    #           ],
    #           custom_events_names: [
    #             'Food/Meals',
    #             'Food/Meals',
    #             'Food/Meals',
    #           ],
    #         },
    #       ],
    #     },
    #     {
    #       month: 2,
    #       days: ['2023-02-05', '2023-02-06', '2023-02-07', '2023-02-08', '2023-02-09', '2023-02-10', '2023-02-11'],
    #       projects: [
    #         {
    #           project_name: 'Project A',
    #           entry_date: '2023-01-15',
    #           exit_date: '2023-02-10',
    #           project_type: 1,
    #           project_type_name: HudUtility.project_type_brief(1),
    #           bed_nights: [
    #             '2023-01-29',
    #             '2023-02-01',
    #             '2023-02-02',
    #           ],
    #           current_situations: [
    #             '2023-01-29',
    #           ],
    #           move_in_dates: [
    #             '2023-01-29',
    #           ],
    #           service_dates: [
    #             '2023-01-29',
    #           ],
    #           ce_events: [
    #             '2023-01-29',
    #           ],
    #           custom_events: [
    #             '2023-01-29',
    #             '2023-02-02',
    #             '2023-02-02',
    #           ],
    #           custom_events_names: [
    #             'Food/Meals',
    #             'Food/Meals',
    #             'Food/Meals',
    #           ],
    #         },
    #       ],
    #     },
    #     {
    #       month: 2,
    #       days: ['2023-02-12', '2023-02-13', '2023-02-14', '2023-02-15', '2023-02-16', '2023-02-17', '2023-02-18'],
    #       projects: [
    #         {
    #           project_name: 'Project B',
    #           entry_date: '2023-02-13',
    #           exit_date: '2023-02-19',
    #           project_type: 3,
    #           project_type_name: HudUtility.project_type_brief(3),
    #           extrapolation: {
    #             entry_date: '2023-02-13',
    #             exit_date: '2023-02-28',
    #           },
    #           bed_nights: [
    #             '2023-02-13',
    #             '2023-02-14',
    #             '2023-02-15',
    #             '2023-02-16',
    #           ],
    #         },
    #         {
    #           project_name: 'RRH Project C',
    #           entry_date: '2023-02-13',
    #           exit_date: nil,
    #           move_in_date: '2023-02-15',
    #           project_type: 13,
    #           project_type_name: HudUtility.project_type_brief(1),
    #           move_in_dates: [
    #             '2023-02-16',
    #           ],
    #         },
    #         {
    #           project_name: 'Project D',
    #           entry_date: '2023-02-13',
    #           exit_date: '2023-02-15',
    #           project_type: 7,
    #           project_type_name: HudUtility.project_type_brief(7),
    #         },
    #         {
    #           project_name: 'Project E testing really really long titles. This needs to be very long.',
    #           entry_date: '2023-02-16',
    #           exit_date: '2023-02-17',
    #           project_type: 4,
    #           project_type_name: HudUtility.project_type_brief(4),
    #           service_dates: [
    #             '2023-02-17',
    #           ],
    #         },
    #       ],
    #     },
    #     {
    #       month: 2,
    #       days: ['2023-02-19', '2023-02-20', '2023-02-21', '2023-02-22', '2023-02-23', '2023-02-24', '2023-02-25'],
    #       projects: [
    #         {
    #           project_id: 1,
    #           project_name: 'Project B',
    #           entry_date: '2023-02-13',
    #           exit_date: '2023-02-19',
    #           project_type: 3,
    #           project_type_name: HudUtility.project_type_brief(3),
    #           extrapolation: {
    #             entry_date: '2023-02-13',
    #             exit_date: '2023-02-28',
    #           },
    #           bed_nights: [
    #             '2023-02-13',
    #             '2023-02-14',
    #             '2023-02-15',
    #             '2023-02-16',
    #           ],
    #         },
    #         {
    #           project_name: 'RRH Project C',
    #           entry_date: '2023-02-13',
    #           exit_date: nil,
    #           move_in_date: '2023-02-15',
    #           project_type: 13,
    #           project_type_name: HudUtility.project_type_brief(1),
    #         },
    #       ],
    #     },
    #     {
    #       month: 2,
    #       days: ['2023-02-26', '2023-02-27', '2023-02-28', '2023-03-01', '2023-03-02', '2023-03-03', '2023-03-04'],
    #       projects: [
    #         {
    #           project_name: 'Project B',
    #           entry_date: '2023-02-13',
    #           exit_date: '2023-02-19',
    #           extrapolation_only: true,
    #           project_type: 3,
    #           project_type_name: HudUtility.project_type_brief(3),
    #           extrapolation: {
    #             entry_date: '2023-02-13',
    #             exit_date: '2023-02-28',
    #           },
    #           bed_nights: [
    #             '2023-02-13',
    #             '2023-02-14',
    #             '2023-02-15',
    #             '2023-02-16',
    #           ],
    #         },
    #         {
    #           project_name: 'RRH Project C',
    #           entry_date: '2023-02-13',
    #           exit_date: nil,
    #           move_in_date: '2023-02-15',
    #           project_type: 13,
    #           project_type_name: HudUtility.project_type_brief(1),
    #         },
    #       ],
    #     },
    #   ]
    # else
    #   data = fake_data.select do |month|
    #     month[:month] == @month && month[:year] == @year
    #   end.first || {}
    #   data[:weeks]
    # end
  end
end
