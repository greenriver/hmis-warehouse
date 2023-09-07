module AllNeighborsSystemDashboard
  class HousingTotalPlacementsData
    def initialize(start_date, end_date)
      @start_date = start_date.beginning_of_month
      @end_date = end_date.beginning_of_month
    end

    def date_range
      date_range = []
      current_date = @start_date
      while current_date <= @end_date
        date_range.push(current_date)
        current_date += 1.month
      end
      date_range
    end

    def total_data
      [
        {
          project_type: 'All',
          count_levels: [
            {
              count_level_name: 'Individuals',
              series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..1500)] },
            },
            {
              count_level_name: 'Households',
              series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..500)] },
            },
          ],
        },
        {
          project_type: 'Diversion',
          count_levels: [
            {
              count_level_name: 'Individuals',
              series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..1500)] },
            },
            {
              count_level_name: 'Households',
              series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..500)] },
            },
          ],
        },
      ]
    end

    def donut_data
      [
        {
          title: 'Project Type',
          id: 'project_type',
          count_levels: [
            {
              count_level_name: 'Individuals',
              total: 826,
              series: [
                {
                  name: 'Rapid-Rehousing',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..1500)] },
                  key: 'rapid',
                  color: '#1865AB',
                },
                {
                  name: 'Permanent Housing',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..1500)] },
                  key: 'permanent',
                  color: '#B2803F',
                },

              ],
            },
            {
              count_level_name: 'Households',
              total: 200,
              series: [
                {
                  name: 'Rapid-Rehousing',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..500)] },
                  key: 'rapid',
                  color: '#1865AB',
                },
                {
                  name: 'Permanent Housing',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..500)] },
                  key: 'permanent',
                  color: '#B2803F',
                },

              ],
            },
          ],
        },
        {
          title: 'Household Type',
          id: 'household_type',
          count_levels: [
            {
              count_level_name: 'Individuals',
              total: 826,
              series: [
                {
                  name: 'Adults Only',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..1500)] },
                  key: 'adults_only',
                  color: '#3B528B',
                },
                {
                  name: 'Adults and Children',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..1500)] },
                  key: 'adults_and_children',
                  color: '#ABBD2A',
                },
              ],
            },
            {
              count_level_name: 'Households',
              total: 300,
              series: [
                {
                  name: 'Adults Only',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..500)] },
                  key: 'adults_only',
                  color: '#3B528B',
                },
                {
                  name: 'Adults and Children',
                  series: date_range.map { |date| [date.strftime('%Y-%m-%d'), rand(10..500)] },
                  key: 'adults_and_children',
                  color: '#ABBD2A',
                },
              ],
            },
          ],
        },
      ]
    end
  end
end
