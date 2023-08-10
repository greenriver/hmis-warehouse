class ClientHistoryMonth
  CONTACT_TYPES = {
    'current_situations' => { name: 'Current Living Situation', icon: 'icon-download2' },
    'move_in_dates' => { name: 'Move-in Date', icon: 'icon-enter' },
    'extension' => { name: 'Extrapolated', icon: 'icon-cross' },
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

  def weeks_data
    if @month == 2 && @year == 2023
      [
        {
          month: 2,
          days: ['2023-01-29', '2023-01-30', '2023-01-31', '2023-02-01', '2023-02-02', '2023-02-03', '2023-02-04'],
          projects: [
            {
              project_name: 'Project A',
              entry_date: '2023-01-15',
              exit_date: '2023-02-10',
              project_type: 1,
              project_type_name: HudUtility.project_type_brief(1),
              bed_nights: [
                '2023-01-29',
                '2023-02-01',
                '2023-02-02',
              ],
              current_situations: [
                '2023-01-29',
              ],
              move_in_dates: [
                '2023-01-29',
              ],
              service_dates: [
                '2023-01-29',
              ],
              ce_events: [
                '2023-01-29',
              ],
              custom_events: [
                '2023-01-29',
                '2023-02-02',
                '2023-02-02',
              ],
              custom_events_names: [
                'Food/Meals',
                'Food/Meals',
                'Food/Meals',
              ],
            },
          ],
        },
        {
          month: 2,
          days: ['2023-02-05', '2023-02-06', '2023-02-07', '2023-02-08', '2023-02-09', '2023-02-10', '2023-02-11'],
          projects: [
            {
              project_name: 'Project A',
              entry_date: '2023-01-15',
              exit_date: '2023-02-10',
              project_type: 1,
              project_type_name: HudUtility.project_type_brief(1),
              bed_nights: [
                '2023-01-29',
                '2023-02-01',
                '2023-02-02',
              ],
              current_situations: [
                '2023-01-29',
              ],
              move_in_dates: [
                '2023-01-29',
              ],
              service_dates: [
                '2023-01-29',
              ],
              ce_events: [
                '2023-01-29',
              ],
              custom_events: [
                '2023-01-29',
                '2023-02-02',
                '2023-02-02',
              ],
              custom_events_names: [
                'Food/Meals',
                'Food/Meals',
                'Food/Meals',
              ],
            },
          ],
        },
        {
          month: 2,
          days: ['2023-02-12', '2023-02-13', '2023-02-14', '2023-02-15', '2023-02-16', '2023-02-17', '2023-02-18'],
          projects: [
            {
              project_name: 'Project B',
              entry_date: '2023-02-13',
              exit_date: '2023-02-19',
              project_type: 3,
              project_type_name: HudUtility.project_type_brief(3),
              extension: {
                entry_date: '2023-02-13',
                exit_date: '2023-02-28',
              },
              bed_nights: [
                '2023-02-13',
                '2023-02-14',
                '2023-02-15',
                '2023-02-16',
              ],
            },
            {
              project_name: 'RRH Project C',
              entry_date: '2023-02-13',
              exit_date: nil,
              move_in_date: '2023-02-15',
              project_type: 13,
              project_type_name: HudUtility.project_type_brief(1),
              move_in_dates: [
                '2023-02-16',
              ],
            },
            {
              project_name: 'Project D',
              entry_date: '2023-02-13',
              exit_date: '2023-02-15',
              project_type: 7,
              project_type_name: HudUtility.project_type_brief(7),
            },
            {
              project_name: 'Project E testing really really long titles. This needs to be very long.',
              entry_date: '2023-02-16',
              exit_date: '2023-02-17',
              project_type: 4,
              project_type_name: HudUtility.project_type_brief(4),
              service_dates: [
                '2023-02-17',
              ],
            },
          ],
        },
        {
          month: 2,
          days: ['2023-02-19', '2023-02-20', '2023-02-21', '2023-02-22', '2023-02-23', '2023-02-24', '2023-02-25'],
          projects: [
            {
              project_id: 1,
              project_name: 'Project B',
              entry_date: '2023-02-13',
              exit_date: '2023-02-19',
              project_type: 3,
              project_type_name: HudUtility.project_type_brief(3),
              extension: {
                entry_date: '2023-02-13',
                exit_date: '2023-02-28',
              },
              bed_nights: [
                '2023-02-13',
                '2023-02-14',
                '2023-02-15',
                '2023-02-16',
              ],
            },
            {
              project_name: 'RRH Project C',
              entry_date: '2023-02-13',
              exit_date: nil,
              move_in_date: '2023-02-15',
              project_type: 13,
              project_type_name: HudUtility.project_type_brief(1),
            },
          ],
        },
        {
          month: 2,
          days: ['2023-02-26', '2023-02-27', '2023-02-28', '2023-03-01', '2023-03-02', '2023-03-03', '2023-03-04'],
          projects: [
            {
              project_name: 'Project B',
              entry_date: '2023-02-13',
              exit_date: '2023-02-19',
              extension_only: true,
              project_type: 3,
              project_type_name: HudUtility.project_type_brief(3),
              extension: {
                entry_date: '2023-02-13',
                exit_date: '2023-02-28',
              },
              bed_nights: [
                '2023-02-13',
                '2023-02-14',
                '2023-02-15',
                '2023-02-16',
              ],
            },
            {
              project_name: 'RRH Project C',
              entry_date: '2023-02-13',
              exit_date: nil,
              move_in_date: '2023-02-15',
              project_type: 13,
              project_type_name: HudUtility.project_type_brief(1),
            },
          ],
        },
      ]
    else
      data = fake_data.select do |month|
        month[:month] == @month && month[:year] == @year
      end.first || {}
      data[:weeks]
    end
  end
end
