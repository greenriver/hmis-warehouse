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
            entry_date: '2022-01-15',
            exit_date: '2023-02-10',
            project_type: 1,
            bed_nights: [
              '2022-01-30',
              '2023-02-01',
              '2023-02-02',
            ],
            current_living_situations: [
              '2023-02-01',
            ],
          },
          {
            project_name: 'Project B',
            entry_date: '2023-02-03',
            exit_date: nil,
            project_type: 1,
            bed_nights: [
              '2023-02-03',
            ],
          },
        ]
      },
      {
        month: 1,
        days: ['2023-02-05', '2023-02-06', '2023-02-07', '2023-02-08', '2023-02-09', '2023-02-10', '2023-02-11'],
        projects: [
          {
            project_name: 'Project A',
            entry_date: '2022-01-15',
            exit_date: '2023-02-10',
            project_type: 1,
            bed_nights: [
              '2023-02-06',
              '2023-02-09',
            ],
            current_living_situations: [
              '2023-02-10',
            ],
          },
          {
            project_name: 'Project B',
            entry_date: '2023-02-03',
            exit_date: nil,
            project_type: 1,
            bed_nights: [
              '2023-02-10',
            ],
          },
        ]
      },
      {
        month: 1,
        days: ['2023-02-12', '2023-02-13', '2023-02-14', '2023-02-15', '2023-02-16', '2023-02-17', '2023-02-18'],
        projects: [
          {
            project_name: 'Project B',
            entry_date: '2023-02-03',
            exit_date: nil,
            project_type: 1,
          },
          {
            project_name: 'RRH Project C',
            entry_date: '2022-01-13',
            exit_date: nil,
            move_in_date: '2022-01-20',
            project_type: 13,
          }
        ]
      },
      {
        month: 1,
        days: ['2023-02-19', '2023-02-20', '2023-02-21', '2023-02-22', '2023-02-23', '2023-02-24', '2023-02-25'],
        projects: [
          {
            project_name: 'Project B',
            entry_date: '2023-02-03',
            exit_date: '2023-02-19',
            project_type: 1,
          },
        ]
      },
      {
        month: 1,
        days: ['2023-02-26', '2023-02-27', '2023-02-28', '2023-03-01', '2023-03-02', '2023-03-03', '2023-03-04'],
        projects: []
      },
    ]
  end
end