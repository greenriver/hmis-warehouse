module AllNeighborsSystemDashboard
  class TimeToObtainHousing < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.stacked_data
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      Rails.cache.fetch("#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}", expires_in: 1.years) do
        {
          title: title,
          id: id,
          project_types: project_types.map do |project_type|
            {
              project_type: project_type,
              config: {
                keys: keys,
                names: keys.map.with_index { |key, i| [key, (options[:types])[i]] }.to_h,
                colors: keys.map.with_index { |key, i| [key, options[:colors][i]] }.to_h,
                label_colors: keys.map.with_index { |key, i| [key, label_color(options[:colors][i])] }.to_h,
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
                      series: send(type, options.merge({ bars: bars })),
                    }
                  end,
                }
              end,
            }
          end,
        }
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
        ident_to_move_in: { name: 'Identification to Move-In', value: identification_to_move_in },
        ident_to_referral: { name: 'Identification to Referral', value: identification_to_referral },
        referral_to_move_in: { name: 'Referral to Move-In', value: referral_to_move_in },
      }
    end

    private def identification_to_referral
      moved_in_scope.average(datediff(Enrollment, 'day', referral_query, identification_query)).round.abs
    end

    private def identification_to_move_in
      en_t = Enrollment.arel_table
      moved_in_scope.average(datediff(Enrollment, 'day', identification_query, en_t[:move_in_date])).round.abs
    end

    private def referral_to_move_in
      en_t = Enrollment.arel_table
      moved_in_scope.average(datediff(Enrollment, 'day', referral_query, en_t[:move_in_date])).round.abs
    end

    # Identification occurs at the earlier or CE Entry, CE Referral, or Enrollment Entry Date
    private def identification_query
      en_t = Enrollment.arel_table
      cl(en_t[:ce_entry_date], en_t[:ce_referral_date], en_t[:entry_date])
    end

    # Referral occurs at the later of CE event, CE entry, or if neither of those, enrollment entry date
    private def referral_query
      en_t = Enrollment.arel_table
      cl(en_t[:ce_referral_date], en_t[:ce_entry_date], en_t[:entry_date])
    end

    private def moved_in_scope
      report_enrollments_enrollment_scope.
        moved_in
    end

    # FIXME
    def stack(options)
      project_type = options[:project_type]
      homelessness_status = options[:homelessness_status]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars[0] = "#{homelessness_status} #{bars[0]}" if homelessness_status.present?
      bars.map do |bar|
        {
          name: bar,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |_| 1_500 },
            }
          end,
        }
      end
    end
  end
end
