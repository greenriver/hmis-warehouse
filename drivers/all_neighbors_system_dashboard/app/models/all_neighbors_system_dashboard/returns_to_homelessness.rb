###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class ReturnsToHomelessness < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.returns_data
    end

    # Date should be the first of the month, range will extend through the month
    def clients_for_date(date:, count_level:, project_type:)
      count_item = count_one_client_per_date_arel
      scope = returned_total_scope
      scope = filter_for_type(scope, project_type)
      scope = filter_for_count_level(scope, count_level)
      scope = filter_for_date(scope, date)
      scope.pluck(count_item)
    end

    def project_types_with_data
      # FIXME: needs to be based on the data available
      project_types
      # raise 'hi'
      # @project_types_with_data ||= line_data[:project_types].
      #   # Reject any project types where we have NO data
      #   reject { |m| m[:count_levels].flatten.map { |n| n[:monthly_counts] }.flatten(2).map(&:last)&.all?(0) }.
      #   map { |m| m[:project_type] }
    end

    # Count once per client per day
    # NOTE: the enrollments table will never have more than one enrollment
    # per client per day
    private def count_one_client_per_date_arel
      nf(
        'concat',
        [
          Enrollment.arel_table[:destination_client_id],
          ' ',
          Enrollment.arel_table[:placed_date],
        ],
      )
    end

    private def aggregate(series)
      total_count = 0
      series.map do |date, counts|
        total_count += counts
        [
          date,
          total_count,
        ]
      end
    end

    private def filter_for_date(scope, date, start_date: date.beginning_of_month)
      range = start_date .. date.end_of_month
      scope.placed_in_range(range)
    end

    # Example format of options: {:types=>['Adult Only', 'Adults and Children', 'Unknown Household Type'], :colors=>["#E6B70F", "#B2803F", "#1865AB"], :project_type=>"All", :count_level=>"Individuals"}
    def returns(options, count_item:, **)
      project_type = options[:project_type] || options[:homelessness_status]
      dates = date_range.map do |date|
        counts_for_placed = options[:types].map do |type|
          placed_scope = housed_total_scope.select(count_item)
          placed_scope = filter_for_type(placed_scope, project_type)
          placed_scope = filter_for_type(placed_scope, type)
          placed_scope = filter_for_count_level(placed_scope, options[:count_level])
          placed_scope = filter_for_date(placed_scope, date)
          placed_count = mask_small_populations(placed_scope.count, mask: @report.mask_small_populations?)
          placed_count = options[:hide_others_when_not_all] && project_type != 'All' && type != project_type ? 0 : placed_count
          placed_count
        end
        counts_for_returns = options[:types].map do |type|
          return_scope = returned_total_scope.select(Enrollment.arel_table[:return_date])
          return_scope = filter_for_type(return_scope, project_type)
          return_scope = filter_for_type(return_scope, type)
          return_scope = filter_for_count_level(return_scope, options[:count_level])
          return_scope = filter_for_date(return_scope, date)
          return_count = mask_small_populations(return_scope.count, mask: @report.mask_small_populations?)
          return_count = options[:hide_others_when_not_all] && project_type != 'All' && type != project_type ? 0 : return_count
          return_count
        end
        {
          date: date.strftime('%Y-%-m-%-d'),
          values: [
            counts_for_placed,
            counts_for_returns,
          ],
        }
      end
      dates
    end

    #   {
    #     projectType: 'All',
    #     countLevel: 'Individuals',
    #     demographics: 'All',
    #   } => {
    #     config: {
    #       names: ['Placements', 'Returns'],
    #       colors: ['#336770', '#E6B70F'],
    #       label_colors: ['#ffffff', '#000000'],
    #     },
    #     series: [
    #       {
    #         date: '2020-01-01',
    #         values: [10, 3],
    #       },
    #       {
    #         date: '2020-02-01',
    #         values: [12, 2],
    #       },
    #     ],
    #   },
    # }
    def returns_data
      [].tap do |data|
        project_types.each do |project_type|
          count_levels.each do |count_level|
            (['All'] + demographics).each do |demo|
              key = {
                projectType: project_type,
                countLevel: count_level,
                demographics: demo,
              }
              categories = case demo
              when 'All'
                ['All']
              when 'Race'
                demographic_race
              when 'Age'
                demographic_age
              when 'Gender'
                demographic_gender
              when 'Household Type'
                household_types
              end
              names = ['Placements', 'Returns']
              colors = ['#336770', '#E6B70F']
              label_colors = names.zip(colors).to_h.transform_values { |v| label_color(v) }
              data << [
                key,
                {
                  config: {
                    names: names,
                    colors: colors,
                    label_colors: label_colors,
                    axis: {
                      x: {
                        type: 'category',
                        categories: categories,
                      },
                    },
                  },
                  series: returns({ types: categories, project_type: project_type, count_level: count_level }, count_item: count_one_client_per_date_arel),
                },
              ]
            end
          end
        end
      end
    end
  end
end
