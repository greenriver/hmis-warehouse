###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class TimeToObtainHousing < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.stacked_data
    end

    # Reject any project types where we have NO data
    def project_types_with_data
      @project_types_with_data ||= stacked_data[:project_types].reject { |m| m[:household_types].flatten.first[:demographics].first[:series].map { |t| t[:series].map { |r| r[:values] } }.flatten.all?(0) }.map { |m| m[:project_type] }
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      identifier = "#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?

      data = {
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
                    series: send(type, options.merge({ bars: bars, project_type: project_type, household_type: household_type })),
                  }
                end,
              }
            end,
          }
        end,
      }

      @report.datasets.create!(
        identifier: identifier,
        data: data,
      )
      data
    end

    def overall_average_time(category = :referral_to_move_in)
      # There must be a better way to obtain this
      # We are duplicating the JavaScript logic so this ends up being the same value as the overall chart
      # Force a run of stacked_data to ensure we have the values, something is up with the caching
      stacked_data
      records = stacked_data[:project_types].first['household_types'].first['demographics'].first['series'].detect { |s| s['name'] == 'Overall' }['series']
      # values are [id->referral, referral->move-in]
      household_count = 0
      averages = 0

      records.each do |row|
        household_count += row['households_count']
        days = case category
        when :referral_to_move_in
          row['values'].last
        when :identification_to_move_in
          row['values'].sum
        else
          raise "Unknown category: #{category}"
        end
        averages += days * row['households_count']
      end
      return 0 if averages.zero? || household_count.zero?

      # Enforce full division here, we'll round at display time
      averages.to_f / household_count
    end

    def stacked_data
      return data(
        'Household Average Days from Identification to Housing by Race',
        'household_average_days',
        :stack,
        options: {
          types: ['ID to Referral', 'Referral to Move-in'],
          colors: ['#336770', '#E6B70F'],
          label_colors: ['#ffffff', '#000000'],
        },
      )
    end

    def overall_data
      # ids need to match the types above (except total)
      {
        ident_to_move_in: { name: 'Identification to Move-In', id: to_key('total') },
        # ident_to_referral: { name: 'Identification to Referral', id: to_key('ID to Referral') },
        # referral_to_move_in: { name: 'Referral to Move-In', id: to_key('Referral to Move-in') },
      }
    end

    private def identification_to_referral(scope = moved_in_scope)
      scope.average(datediff(Enrollment, 'day', referral_query, identification_query))&.round&.abs || 0
    end

    private def identification_to_move_in(scope = moved_in_scope)
      en_t = Enrollment.arel_table
      scope.average(datediff(Enrollment, 'day', identification_query, en_t[:move_in_date]))&.round&.abs || 0
    end

    private def referral_to_move_in(scope = moved_in_scope)
      en_t = Enrollment.arel_table
      scope.average(datediff(Enrollment, 'day', referral_query, en_t[:move_in_date]))&.round&.abs || 0
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

    # For the purposes of time to obtain housing, only clients with a move-in date, CE Entry Date, and CE Referral Date
    # are included in the calculation
    # In addition, we only look at households for time to obtain housing, so always limit to HoH
    private def moved_in_scope
      with_ce_data.hoh.
        moved_in_in_range(@report.filter.range, filter: @report.filter)
    end

    private def filter_for_date(scope, date)
      range = date.beginning_of_month .. date.end_of_month
      where_clause = date_query(range)
      scope.where(where_clause)
    end

    private def date_query(range)
      en_t = Enrollment.arel_table
      en_t[:move_in_date].between(range)
    end

    def stack(options)
      project_type = options[:project_type]
      homelessness_status = options[:homelessness_status]
      bars = options[:bars]
      bars[0] = "#{homelessness_status} #{bars[0]}" if homelessness_status.present?
      bars.map do |bar|
        {
          name: bar,
          series: date_range.map do |date|
            household_scope = moved_in_scope.select(:destination_client_id).distinct
            household_scope = filter_for_type(household_scope, bar)
            household_scope = filter_for_date(household_scope, date)
            averages = options[:types].map do |category|
              scope = moved_in_scope
              # Filter for high level type
              scope = filter_for_type(scope, project_type)
              # Filter for household type (need to write the filter logic)
              scope = filter_for_type(scope, options[:household_type])
              scope = filter_for_date(scope, date)
              scope = filter_for_type(scope, bar)
              case category
              when 'ID to Referral'
                identification_to_referral(scope)
              when 'Referral to Move-in'
                referral_to_move_in(scope)
              else
                raise "Unknown Category #{category}"
              end
            end
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: averages,
              households_count: mask_small_populations(household_scope.count, mask: @report.mask_small_populations?),
            }
          end,
        }
      end
    end
  end
end
