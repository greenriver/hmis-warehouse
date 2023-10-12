module AllNeighborsSystemDashboard
  class FakeTimeToObtainHousing < FakeData
    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        quarters: quarter_range,
        project_types: project_types.map do |project_type|
          {
            project_type: project_type,
            config: {
              keys: options[:by_project_type] && project_type != 'All' ? [to_key(project_type)] : keys,
              names: keys.map.with_index { |key, i| [key, (options[:types])[i]] }.to_h,
              colors: keys.map.with_index { |key, i| [key, options[:colors][i]] }.to_h,
              label_colors: keys.map.with_index { |key, i| [key, label_color(options[:colors][i])] }.to_h,
              shapes: keys.map.with_index do |key, i|
                index = i < 3 ? i : i % 3
                [key, (options[:shapes] || [])[index]]
              end.to_h,
            },
            household_types: (['All'] + household_types).map do |household_type|
              {
                household_type: household_type,
                demographics: demographics.map do |demo|
                  demo_names_meth = "demographic_#{demo.gsub(' ', '').underscore}".to_sym
                  filter_bars = demo_names_meth == :demographic_household_type && household_type != 'All'
                  demo_names = send(demo_names_meth)
                  demo_bars = filter_bars ? demo_names.select { |bar| bar == household_type } : demo_names
                  bars = (['Overall'] + demo_bars)
                  {
                    demographic: demo,
                    series: send(type, options.merge({ bars: bars, project_type: project_type })),
                  }
                end,
              }
            end,
          }
        end,
      }
    end

    def line_data
      data(
        'Household Average Days from Identification to Referral to Move-In',
        'average_days_id_referral_move',
        :line,
        options: {
          types: ['ID to Referral', 'Referral to Move In', 'ID to Move In'],
          colors: ['#336770', '#E6B70F', '#2979FF'],
          label_colors: ['#ffffff', '#000000', '#ffffff'],
          shapes: ['rectangle', 'triangle', 'circle'],
        },
      )
    end

    def scatter_data
      data(
        'Average Days from Referral to Move-In by Project',
        'average_days_id_referral_move_by_project',
        :scatter,
        options: {
          types: project_types.reject { |d| d == 'All' },
          colors: project_type_colors,
          label_colors: Array.new(project_type_colors.size, '#ffffff'),
          shapes: ['rectangle', 'triangle', 'circle'],
          by_project_type: true,
        },
      )
    end

    def scatter(options)
      project_type = options[:project_type]
      types = options[:types] || []
      types = types.select { |t| t == project_type } if options[:by_project_type] && project_type != 'All'
      types.map do |_|
        date_range.map do |date|
          [date.strftime('%Y-%-m-%-d'), rand(0..160), rand(40..200)]
        end
      end
    end

    def line(options)
      project_type = options[:project_type]
      types = options[:types] || []
      types = types.select { |t| t == project_type } if options[:by_project_type] && project_type != 'All'
      types.map.with_index do |_d, i|
        base = 100
        super(quarter_range, options.merge(range: [i * base, (i + 1) * base]))
      end
    end

    def stacked_data
      return data(
        'Household Average Days from Identification to Housing by Race',
        'household_average_days',
        :stack,
        options: {
          types: ['ID to Referral', 'Referral to Move-in*'],
          colors: ['#336770', '#E6B70F'],
          label_colors: ['#ffffff', '#000000'],
        },
      )
    end

    def overall_data
      {
        ident_to_move_in: { name: 'Identification to Move-In', value: 223 },
        ident_to_referral: { name: 'Identification to Referral', value: 127 },
        referral_to_move_in: { name: 'Referral to Move-In', value: 96 },
      }
    end
  end
end
