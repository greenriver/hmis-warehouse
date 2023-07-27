class ClientHistoryMonth
  def initialize(year, month)
  end

  def weeks_data
    [
      {
        month: 1,
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
            ],
          },
        ],
      },
      {
        month: 1,
        days: ['2023-02-05', '2023-02-06', '2023-02-07', '2023-02-08', '2023-02-09', '2023-02-10', '2023-02-11'],
        projects: [
          {
            project_name: 'Project A',
            entry_date: '2023-01-15',
            exit_date: '2023-02-10',
            project_type: 1,
            project_type_name: HudUtility.project_type_brief(1),
            bed_nights: [
              '2023-02-06',
              '2023-02-09',
            ],
            current_situations: [
              '2023-02-10',
            ],
          },
        ],
      },
      {
        month: 1,
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
            ],
            current_situations: [
              '2023-02-13',
            ],
            move_in_dates: [
              '2023-02-13',
            ],
            service_dates: [
              '2023-02-13',
            ],
            ce_events: [
              '2023-02-13',
            ],
            custom_events: [
              '2023-02-13',
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
        month: 1,
        days: ['2023-02-19', '2023-02-20', '2023-02-21', '2023-02-22', '2023-02-23', '2023-02-24', '2023-02-25'],
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
        month: 1,
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
  end
end
