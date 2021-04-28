###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
module PublicReports
  class HomelessPopulation < ::PublicReports::Report
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    acts_as_paranoid

    def title
      _('Homeless Population Report Generator')
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
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}/"
      end
    end

    def publish!(content)
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      self.class.transaction do
        unpublish_similar
        update(
          html: content,
          published_url: generate_publish_url, # NOTE this isn't used in this report
          embed_code: generate_embed_code, # NOTE this isn't used in this report
          state: :published,
        )
      end
      push_to_s3
    end

    # Override default push to s3 to enable multiple files
    private def push_to_s3
      bucket = s3_bucket
      populations.keys.each do |population|
        prefix = File.join(public_s3_directory, population.to_s)
        section_html = html_section(population)
        # binding.pry

        key = File.join(prefix, 'index.html')

        resp = s3_client.put_object(
          acl: 'public-read',
          bucket: bucket,
          key: key,
          body: section_html,
        )
        if resp.etag
          Rails.logger.info 'Successfully uploaded report file to s3'
        else
          Rails.logger.info 'Unable to upload report file'
        end
      end
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    def generate_publish_url_for(population)
      "#{generate_publish_url}#{population}/index.html"
    end

    def generate_embed_code_for(population)
      "<iframe width='500' height='400' src='#{generate_publish_url_for(population)}' frameborder='0' sandbox><a href='#{generate_publish_url_for(population)}'>#{instance_title} -- #{population.to_s.humanize}</a></iframe>"
    end

    def view_template
      populations.keys
    end

    def populations
      {
        overall: _('People Experiencing Homelessness'),
        housed: _('People Housed'),
        individuals: _('Individuals'),
        adults_with_children: _('People in Families'),
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
      # mem = GetProcessMem.new
      # puts "STARTING: calculate_data for #{population}"
      # puts mem.mb
      {
        pit_chart: pit_chart(population),
        pit_family_hoh_chart: pit_family_hoh_chart(population),
        location_chart: location_chart(population),
        gender_chart: gender_chart(population),
        age_chart: age_chart(population),
        time_homeless: time_homeless(population),
        time_housed: time_housed(population),
        race_chart: race_chart(population),
        household_chart: household_chart(population),
        average_household_size: average_household_size(population),
      }
    end

    private def pit_chart(population)
      title = populations[population]
      housed_title = if population == :housed
        title
      else
        "#{title} Housed"
      end
      x = ['x']
      homeless = [title]
      housed = [housed_title]
      data = []
      changes = {}
      changes[title] = ['Percent change from prior quarter'] unless population == :housed
      changes[housed_title] = ['Percent change from prior quarter']
      pit_counts(population).each do |date, counts|
        x << date
        homeless << counts[:homeless_count] unless population == :housed
        housed << counts[:housed_count]
        changes[title] << counts[:homeless_change] unless population == :housed
        changes[housed_title] << counts[:housed_change]
      end
      data << x
      data << homeless unless population == :housed
      data << housed
      { data: data, change: changes, title: title }.to_json
    end

    private def pit_family_hoh_chart(population)
      return {}.to_json unless population == :adults_with_children

      title = 'Families'
      housed_title = "#{title} Housed"
      x = ['x']
      homeless = [title]
      housed = [housed_title]
      changes = {
        title => ['Percent change from prior quarter'],
        housed_title => ['Percent change from prior quarter'],
      }
      data = []
      pit_counts(:hoh_from_adults_with_children).each do |date, counts|
        x << date
        homeless << counts[:homeless_count]
        housed << counts[:housed_count]
        changes[title] << counts[:homeless_change]
        changes[housed_title] << counts[:housed_change]
      end
      data << x
      data << homeless
      data << housed
      { data: data, change: changes, title: title }.to_json
    end

    private def pit_counts(population)
      data = quarter_dates.map do |date|
        [
          date.iso8601,
          {
            homeless_count: client_count_for_date(date, population, :homeless),
            housed_count: client_count_for_date(date, population, :residential_non_homeless),
          },
        ]
      end.to_h
      data.each_with_index do |(date, counts), i|
        homeless_change = 0
        housed_change = 0
        if i.positive?
          if counts[:homeless_count].positive?
            prior_homeless_count = data[quarter_dates[i - 1].iso8601][:homeless_count]
            homeless_change = (((counts[:homeless_count] - prior_homeless_count.to_f) / counts[:homeless_count].to_f) * 100).round
          end
          if counts[:housed_count].positive?
            prior_housed_count = data[quarter_dates[i - 1].iso8601][:housed_count]
            housed_change = (((counts[:housed_count] - prior_housed_count.to_f) / counts[:housed_count].to_f) * 100).round
          end
        end
        data[date][:homeless_change] = homeless_change
        data[date][:housed_change] = housed_change
      end
      data
    end

    private def client_count_for_date(date, population, she_scope)
      scope = with_service_in_quarter(report_scope, date, population).
        select(:client_id).
        distinct
      # NOTE age calculations need to be done for the day in question

      # limit final count to the appropriate housing type
      scope.send(she_scope).count
    end

    private def scope_for(population, date, scope)
      case population
      when :homeless
        scope = scope.homeless
      when :housed
        scope = scope.permanent_housing
      when :individuals
        scope = scope.where.not(household_id: adult_and_child_household_ids(date))
      when :adults_with_children
        scope = scope.where(household_id: adult_and_child_household_ids(date))
      when :hoh_from_adults_with_children
        scope = scope.where(household_id: adult_and_child_household_ids(date)).heads_of_households
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

    private def child_only_household_ids(date)
      report_scope.service_on_date(date).where.not(household_id: nil).
        group(:household_id).
        having(nf('count', [shs_t[:age].gteq(18)]).eq(0).and(nf('count', [shs_t[:age].lt(18)]).gt(1))).
        select(:household_id)
    end

    private def total_for(scope, population)
      count = if population == :adults_with_children
        scope.select(:household_id).distinct.count
      else
        scope.select(:client_id).distinct.count
      end

      word = case population
      when :veterans
        'Veteran'
      when :adults_with_children, :hoh_from_adults_with_children
        'Household'
      else
        'Person'
      end

      pluralize(number_with_delimiter(count), word)
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
              total: total_for(with_service_in_quarter(report_scope, date, population), population),
            }
          when :homeless
            charts[date.iso8601] = {
              data: [
                ['Sheltered', with_service_in_quarter(report_scope, date, population).homeless_sheltered.select(:client_id).distinct.count],
                ['Unsheltered', with_service_in_quarter(report_scope, date, population).homeless_unsheltered.select(:client_id).distinct.count],
              ],
              title: _('Where People are Staying'),
              total: total_for(with_service_in_quarter(report_scope, date, population), population),
            }
          else
            charts[date.iso8601] = {
              data: [
                ['Homeless', with_service_in_quarter(report_scope, date, population).homeless.select(:client_id).distinct.count],
                ['Housed', with_service_in_quarter(report_scope, date, population).residential_non_homeless.select(:client_id).distinct.count],
              ],
              title: _('Homeless or Housed'),
              total: total_for(with_service_in_quarter(report_scope, date, population), population),
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
      scope = scope_for(population, date, scope).
        with_service_between(
          start_date: date,
          end_date: date.end_of_quarter,
          service_scope: service_scope,
        )
      # NOTE: all scopes should only include people who were homeless in the quarter in question, except the housed scope
      return scope if population == :housed

      # enforce that the clients have some homeless history within the
      # quarter in-question, but allow all of their appropriate history
      # to be included
      homeless_scope = scope.where(client_id: scope.homeless.select(:client_id))
      scope.where(id: homeless_scope)
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
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
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
            where(shs_t[:date].between(date..date.end_of_quarter)). # hint for performance
            pluck(shs_t[:client_id], shs_t[:age]).
            each do |client_id, age|
              data[bucket_age(age)] << client_id unless client_ids.include?(client_id)
              client_ids << client_id
            end
          charts[date.iso8601] = {
            data: data.map { |age, ids| [age_name(age), ids.count] },
            title: _('Age'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
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

    private def age_name(age)
      ages = {
        0 => 'Under 18',
        18 => '18 to 64',
        65 => 'Over 65',
        unknown: 'Unknown',
      }.freeze
      ages[age]
    end

    private def race_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          client_ids = Set.new
          client_cache = GrdaWarehouse::Hud::Client.new
          data = {}
          census_data = {}
          # Add census info
          ::HUD.races(multi_racial: true).each do |key, label|
            census_data[label] = 0
            census_data[label] = GrdaWarehouse::FederalCensusBreakdowns::Coc.coc_level.with_geography(coc_codes).with_measure(key).sum(:value) / full_census_count.to_f if full_census_count&.positive?
          end
          all_destination_ids = with_service_in_quarter(report_scope, date, population).distinct.pluck(:client_id)
          with_service_in_quarter(report_scope, date, population).
            joins(:client).
            preload(:client).
            order(first_date_in_program: :desc). # Use the newest start
            find_each do |enrollment|
              client = enrollment.client
              race = client_cache.race_string(destination_id: client.id, scope_limit: client.class.where(id: all_destination_ids))
              data[::HUD.race(race, multi_racial: true)] ||= Set.new
              data[::HUD.race(race, multi_racial: true)] << client.id unless client_ids.include?(client.id)
              client_ids << client.id
            end
          total_count = data.map { |_, ids| ids.count }.sum
          # Format:
          # [["Black or African American",38, 53],["White",53, 76],["Native Hawaiian or Other Pacific Islander",1, 12],["Multi-Racial",4, 10],["Asian",1, 5],["American Indian or Alaska Native",1, 1]]
          combined_data = data.map do |race, ids|
            label = if race == 'None'
              'Unknown'
            else
              race
            end
            [
              label,
              ids.count / total_count.to_f, # Homeless Data
              census_data[race], # Federal Census Data
            ]
          end
          charts[date.iso8601] = {
            # then the title for the tooltip needs to be adjusted for 0, 1 where 0 is homeless population, 1 is whole population
            # data for census population is stored in GrdaWarehouse::FederalCensusBreakdowns:Coc
            # get distinct on max date prior to date in question with identifier and measure
            # use distinct ProjectCoC.CoCCodes to determine the scope for census data
            # sum value after getting appropriate set of rows
            # add index on [accurate_on, identifier, type, measure]
            data: combined_data,
            title: _('Racial Composition'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
            categories: ['Homeless Population', 'Overall Population'],
          }
        end
      end
    end

    private def full_census_count
      @full_census_count ||= GrdaWarehouse::FederalCensusBreakdowns::Coc.coc_level.with_geography(coc_codes).full_set.with_measure(:all).sum(:value)
    end

    private def coc_codes
      @coc_codes ||= report_scope.joins(project: :project_cocs).distinct.
        pluck(pc_t[:hud_coc_code], pc_t[:CoCCode]).map do |override, original|
          override.presence || original
        end
    end

    private def household_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = {}
          counted_clients = Set.new
          with_service_in_quarter(report_scope, date, population).
            joins(client: :processed_service_history).
            preload(client: :processed_service_history).
            find_each do |enrollment|
              client = enrollment.client
              data[client_population(enrollment, date)] ||= 0
              data[client_population(enrollment, date)] += 1 unless counted_clients.include?(client.id)
              counted_clients << client.id
            end
          charts[date.iso8601] = {
            data: data.to_a,
            title: _('Household Composition'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
          }
        end
      end
    end

    private def client_population(enrollment, date)
      return 'Adult and Child' if adult_and_child_household_ids_by_date(date).include?(enrollment.household_id)
      return 'Child Only' if child_only_household_ids_by_date(date).include?(enrollment.household_id)

      'Adult Only'
    end

    private def adult_and_child_household_ids_by_date(date)
      @adult_and_child_household_ids_by_date ||= {}
      @adult_and_child_household_ids_by_date[date] ||= adult_and_child_household_ids(date).pluck(:household_id)

      @adult_and_child_household_ids_by_date[date]
    end

    private def child_only_household_ids_by_date(date)
      @child_only_household_ids_by_date ||= {}
      @child_only_household_ids_by_date[date] ||= child_only_household_ids(date).pluck(:household_id)

      @child_only_household_ids_by_date[date]
    end

    private def average_household_size(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = []
          with_service_in_quarter(report_scope, date, population).
            where.not(household_id: nil).
            joins(client: :processed_service_history).
            group(:household_id).
            select(:client_id).distinct.count.
            each do |_, count|
              data << count
            end
          data = [0] if data.empty?
          charts[date.iso8601] = {
            data: (data.sum.to_f / data.count).round,
            title: _('Average Household Size'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
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
            joins(client: :processed_service_history).
            preload(client: :processed_service_history).
            find_each do |enrollment|
              client = enrollment.client
              data[bucket_days(client.days_homeless(on_date: date))] ||= 0
              data[bucket_days(client.days_homeless(on_date: date))] += 1 unless counted_clients.include?(client.id)
              counted_clients << client.id
            end
          charts[date.iso8601] = {
            data: data.to_a,
            title: _('Time Homeless'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
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
            joins(client: :processed_service_history).
            preload(client: :processed_service_history).
            find_each do |enrollment|
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
            data: data.to_a,
            title: _('Time in Project'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
          }
        end
      end
    end
  end
end
