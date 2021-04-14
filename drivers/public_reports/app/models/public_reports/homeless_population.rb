###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class HomelessPopulation < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Homeless Population Generator')
    end

    def instance_title
      _('Homeless Population Report')
    end

    private def public_s3_directory
      'homeless-population'
    end

    def url
      public_reports_warehouse_reports_homeless_populations_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    def generate_publish_url
      # TODO: This is the standard S3 public access, it will need to be updated
      # when moved to CloudFront
      if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}/index.html"
      end
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    def populations
      {
        overall: _('People Experiencing Homelessness'),
        housed: _('People Housed'),
        individuals: _('Individuals'),
        adults_with_children: _('Families'),
        veterans: _('Veterans'),
      }
    end

    private def chart_data
      {
        # count: percent_change_in_count,
        date_range: filter_object.date_range_words,
        overall: calculate_data(:overall),
        housed: calculate_data(:housed),
        individuals: calculate_data(:individuals),
        adults_with_children: calculate_data(:adults_with_children),
        veterans: calculate_data(:veterans),
      }.to_json
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def report_scope
      # for compatability with FilterScopes
      @filter = filter_object
      @project_types = @filter.project_type_numbers
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope
    end

    private def quarter_dates
      date = filter_object.start_date
      # force the start to be within the chosen date range
      date = date.next_quarter if date.beginning_of_quarter < date
      dates = []
      while date <= filter_object.end_date
        dates << date.beginning_of_quarter
        date = date.next_quarter
      end
      dates
    end

    private def calculate_data(population)
      {
        pit_chart: pit_chart(population),
        location_chart: location_chart(population),
        gender_chart: gender_chart(population),
        age_chart: age_chart(population),
        time_homeless: time_homeless(population),
        time_housed: time_housed(population),
        race_chart: race_chart(population),
      }
    end

    private def pit_chart(population)
      title = populations[population]
      x = ['x']
      y = [title]
      z = ['Percent change from prior quarter']
      pit_counts(population).each do |date, counts|
        x << date
        y << counts[:count]
        z << counts[:change]
      end
      { data: [x, y], change: z, title: title }.to_json
    end

    private def pit_counts(population)
      data = quarter_dates.map do |date|
        [
          date.iso8601,
          {
            count: client_count_for_date(date, population),
          },
        ]
      end.to_h
      data.each_with_index do |(date, counts), i|
        change = 0
        if i.positive? && counts[:count].positive?
          prior_count = data[quarter_dates[i - 1].iso8601][:count]
          change = (((counts[:count] - prior_count.to_f) / counts[:count].to_f) * 100).round
        end
        data[date][:change] = change
      end
      data
    end

    private def client_count_for_date(date, population)
      scope = report_scope.service_on_date(date).
        select(:client_id).
        distinct
      # NOTE age calculations need to be done for the day in question

      scope_for(population, date, scope).count
    end

    private def scope_for(population, date, scope)
      case population
      when :homeless
        scope = scope.homeless
      when :housed
        scope = scope.permanent_housing
      when :individuals
        scope = scope.where(she_t[:household_id].not_in(adult_and_child_household_ids(date)))
      when :adults_with_children
        scope = scope.where(household_id: adult_and_child_household_ids(date))
      when :veterans
        scope = scope.veterans
      end
      scope
    end

    private def adult_and_child_household_ids(date)
      report_scope.service_on_date(date).where.not(household_id: nil).
        group(:household_id).
        having(nf('count', [shs_t[:age].gteq(18)]).gt(1).and(nf('count', [shs_t[:age].lt(18)]).gt(1))).
        select(:household_id)
    end

    private def location_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          case population
          when :housed
            charts[date.iso8601] = {
              data: [
                ['Rapid-Rehousing', with_service_in_quarter(report_scope, date, population).in_project_type(13).select(:client_id).distinct.count],
                ['Permanent Housing', with_service_in_quarter(report_scope, date, population).in_project_type([3, 9, 10]).select(:client_id).distinct.count],
              ],
              title: _('Type of Housing'),
            }
          when :homeless
            charts[date.iso8601] = {
              data: [
                ['Sheltered', with_service_in_quarter(report_scope, date, population).homeless_sheltered.select(:client_id).distinct.count],
                ['Unsheltered', with_service_in_quarter(report_scope, date, population).homeless_unsheltered.select(:client_id).distinct.count],
              ],
              title: _('Where People are Staying'),
            }
          else
            charts[date.iso8601] = {
              data: [
                ['Homeless', with_service_in_quarter(report_scope, date, population).homeless.select(:client_id).distinct.count],
                ['Housed', with_service_in_quarter(report_scope, date, population).residential_non_homeless.select(:client_id).distinct.count],
              ],
              title: _('Homeless vs Housed'),
            }
          end
        end
      end
    end

    private def with_service_in_quarter(scope, date, population)
      service_scope = if population == :housed
        GrdaWarehouse::ServiceHistoryService.where(shs_t[:date].gt(she_t[:move_in_date]))
      else
        :current_scope
      end
      scope_for(population, date, scope).with_service_between(start_date: date, end_date: date.end_of_quarter, service_scope: service_scope)
    end

    # NOTE: this count is equivalent to OutflowReport.exits_to_ph
    private def housed_total_count
      outflow_filter_object = ::Filters::OutflowReport.new.set_from_params(filter['filters'].merge(enforce_one_year_range: false, sub_population: :clients).with_indifferent_access)
      outflow = GrdaWarehouse::WarehouseReports::OutflowReport.new(outflow_filter_object, user)
      outflow.exits_to_ph.count
    end

    private def gender_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          charts[date.iso8601] = {
            data: with_service_in_quarter(report_scope, date, population).
              joins(:client).
              group(c_t[:Gender]).
              count.
              map do |gender_id, count|
                # Force any unknown genders to Unknown
                gender_id = nil unless gender_id.in?([0, 1, 2, 3, 4])
                [
                  ::HUD.gender(gender_id) || 'Unknown',
                  count,
                ]
              end,
            title: _('Gender'),
          }
        end
      end
    end

    private def age_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          client_ids = Set.new
          data = {
            0 => Set.new,
            18 => Set.new,
            65 => Set.new,
            unknown: Set.new,
          }
          with_service_in_quarter(report_scope, date, population).
            joins(:client, :service_history_services).
            order(date: :desc). # Use the greatest age per person for the quarter
            pluck(she_t[:client_id], shs_t[:age]).
            each do |client_id, age|
              data[bucket_age(age)] << client_id unless client_ids.include?(client_id)
              client_ids << client_id
            end
          charts[date.iso8601] = {
            data: data.map { |age, ids| [age, ids.count] },
            title: _('Age'),
          }
        end
      end
    end

    private def bucket_age(age)
      return :unknown if age.blank?
      return 0 if age < 18
      return 18 if age < 65

      65
    end

    private def race_chart(population)
      client_cache = GrdaWarehouse::Hud::Client.new
      {}.tap do |charts|
        quarter_dates.each do |date|
          client_ids = Set.new
          data = {}
          all_destination_ids = with_service_in_quarter(report_scope, date, population).distinct.pluck(:client_id)
          with_service_in_quarter(report_scope, date, population).
            joins(:client).
            order(first_date_in_program: :desc). # Use the newest start
            find_each do |enrollment|
              client = enrollment.client
              race = client_cache.race_string(destination_id: client.id, scope_limit: client.class.where(id: all_destination_ids))
              data[::HUD.race(race, multi_racial: true)] ||= Set.new
              data[::HUD.race(race, multi_racial: true)] << client.id unless client_ids.include?(client.id)
              client_ids << client.id
            end
          charts[date.iso8601] = {
            data: data.map { |race, ids| [race, ids.count] },
            title: _('Racial Composition'),
          }
        end
      end
    end

    private def time_homeless(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = {}
          counted_clients = Set.new
          with_service_in_quarter(report_scope, date, population).
            joins(client: :processed_service_history).find_each do |enrollment|
              client = enrollment.client
              data[bucket_days(client.days_homeless(on_date: date))] ||= 0
              data[bucket_days(client.days_homeless(on_date: date))] += 1 unless counted_clients.include?(client.id)
              counted_clients << client.id
            end
          charts[date.iso8601] = {
            data: data,
            title: _('Time Homeless'),
          }
        end
      end
    end

    private def bucket_days(days)
      return 'less than a month' if days <= 30
      return 'One to six months' if days < 180
      return 'Six to twelve months' if days < 365

      'More than one year'
    end

    private def time_housed(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = {}
          counted_clients = Set.new
          with_service_in_quarter(report_scope, date, population).
            order(first_date_in_program: :desc). # Use most-recently started
            joins(client: :processed_service_history).find_each do |enrollment|
              start_date = if population == :housed
                enrollment.move_in_date
              else
                enrollment.first_date_in_program
              end
              end_date = [enrollment.last_date_in_program, date.end_of_quarter].compact.min
              days = (end_date - start_date).to_i
              data[bucket_days(days)] ||= 0
              data[bucket_days(days)] += 1 unless counted_clients.include?(enrollment.client_id)
              counted_clients << enrollment.client_id
            end
          charts[date.iso8601] = {
            data: data,
            title: _('Time in Project'),
          }
        end
      end
    end
  end
end
