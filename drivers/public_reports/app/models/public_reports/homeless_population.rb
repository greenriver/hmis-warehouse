###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
module PublicReports
  class HomelessPopulation < ::PublicReports::Report
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include GrdaWarehouse::UsCensusApi::Aggregates
    acts_as_paranoid

    MIN_THRESHOLD = 11

    def title
      _('Homeless Populations Report Generator')
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

    private def controller_class
      PublicReports::WarehouseReports::HomelessPopulationsController
    end

    def publish!
      # This should:
      # 1. Take the contents of html and push it up to S3
      # 2. Populate the published_url field
      # 3. Populate the embed_code field
      self.class.transaction do
        unpublish_similar
        update(
          html: as_html,
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
        prefix = File.join(public_s3_directory, version_slug.to_s, population.to_s)
        section_html = html_section(population)

        key = File.join(prefix, 'index.html')

        resp = s3_client.put_object(
          acl: 'public-read',
          bucket: bucket,
          key: key,
          body: section_html,
          content_disposition: 'inline',
          content_type: 'text/html',
        )
        if resp.etag
          Rails.logger.info "Successfully uploaded report file to s3 (#{key})"
        else
          Rails.logger.info "Unable to upload report file (#{key}})"
        end
      end
    end

    private def remove_from_s3
      bucket = s3_bucket
      prefix = public_s3_directory
      populations.keys.each do |population|
        prefix = File.join(public_s3_directory, version_slug.to_s, population.to_s)
        key = File.join(prefix, 'index.html')
        resp = s3_client.delete_object(
          bucket: bucket,
          key: key,
        )
        if resp.delete_marker
          Rails.logger.info "Successfully removed report file from s3 (#{key})"
        else
          Rails.logger.info "Unable to remove the report file (#{key})"
        end
      end
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    def generate_publish_url_for(population)
      publish_url = if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}"
      end
      publish_url = if version_slug.present?
        "#{publish_url}/#{version_slug}/#{population}"
      else
        "#{publish_url}/#{population}"
      end
      "#{publish_url}/index.html"
    end

    def generate_embed_code_for(population)
      "<iframe width='500' height='400' src='#{generate_publish_url_for(population)}' frameborder='0' sandbox='allow-scripts'><a href='#{generate_publish_url_for(population)}'>#{instance_title} -- #{population.to_s.humanize}</a></iframe>"
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
      # scope = filter_for_range(scope) # all future queries limit this by date further, adding it here just makes it slower
      scope = filter_for_user_access(scope)
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
        ethnicity_chart: ethnicity_chart(population),
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
        enforcement_threshold = if population == :hoh_from_adults_with_children
          'hoh_pit_chart'
        else
          'pit_chart'
        end
        [
          date.iso8601,
          {
            homeless_count: enforce_min_threshold(client_count_for_date(date, population, :homeless), enforcement_threshold),
            housed_count: enforce_min_threshold(client_count_for_date(date, population, :residential_non_homeless), enforcement_threshold),
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
        scope = scope.where.not(household_id: adult_and_child_household_ids_by_date(date))
      when :adults_with_children
        scope = scope.where(household_id: adult_and_child_household_ids_by_date(date))
      when :hoh_from_adults_with_children
        scope = scope.where(household_id: adult_and_child_household_ids_by_date(date)).heads_of_households
      when :veterans
        scope = scope.veterans
      end
      scope
    end

    private def word_for(population)
      case population
      when :veterans
        'Veteran'
      when :adults_with_children, :hoh_from_adults_with_children
        'Household'
      else
        'Person'
      end
    end

    private def total_for(scope, population)
      count = scope.select(:client_id).distinct.count
      count = enforce_min_threshold(count, 'min_threshold')

      pluralize(number_with_delimiter(count), word_for(population))
    end

    private def location_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          case population
          when :housed
            rrh = with_service_in_quarter(report_scope, date, population).in_project_type(13).select(:client_id).distinct.count
            psh = with_service_in_quarter(report_scope, date, population).in_project_type([3, 9, 10]).select(:client_id).distinct.count
            (rrh, psh) = enforce_min_threshold([rrh, psh], 'location')

            charts[date.iso8601] = {
              data: [
                ['Rapid-Rehousing', rrh],
                ['Permanent Housing', psh],
              ],
              title: _('Type of Housing'),
              total: total_for(with_service_in_quarter(report_scope, date, population), population),
            }
          when :homeless
            sheltered = with_service_in_quarter(report_scope, date, population).homeless_sheltered.select(:client_id).distinct.count
            unsheltered = with_service_in_quarter(report_scope, date, population).homeless_unsheltered.select(:client_id).distinct.count
            (sheltered, unsheltered) = enforce_min_threshold([sheltered, unsheltered], 'location')

            charts[date.iso8601] = {
              data: [
                ['Sheltered', sheltered],
                ['Unsheltered', unsheltered],
              ],
              title: _('Where People are Staying'),
              total: total_for(with_service_in_quarter(report_scope, date, population), population),
            }
          else
            # We want to count households not all clients for families
            population = :hoh_from_adults_with_children if population == :adults_with_children

            homeless = with_service_in_quarter(report_scope, date, population).homeless.select(:client_id).distinct.count
            housed = with_service_in_quarter(report_scope, date, population).residential_non_homeless.select(:client_id).distinct.count
            (homeless, housed) = enforce_min_threshold([homeless, housed], 'location')

            charts[date.iso8601] = {
              data: [
                ['Homeless', homeless],
                ['Housed', housed],
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

      # The next two lines seem duplicitous - testing
      # homeless_scope = scope.where(client_id: scope.homeless.select(:client_id))
      # scope.where(id: homeless_scope)
      scope.where(client_id: scope.homeless.select(:client_id))
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
          data = with_service_in_quarter(report_scope, date, population).
            joins(:client).
            group(GrdaWarehouse::Hud::Client.gender_binary_sql_case).
            count.
            map do |gender_id, count|
              # Force any count to be at least the minimum allowe
              # Force any unknown genders to Unknown
              gender_id = nil unless gender_id.in?([0, 1, 2, 5, 6])
              [
                ::HUD.gender(gender_id) || 'Unknown',
                count,
              ]
            end.to_h
          data['Unknown'] ||= 0
          counts = data.values
          # Set the total string for the middle before we do cleanup
          word = word_for(population)
          total = with_service_in_quarter(report_scope, date, population).select(:client_id).distinct.count
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end

          counts = enforce_min_threshold(counts, 'donut')

          genders = {}
          data.each.with_index do |(k, _), i|
            genders[k] = counts[i]
          end

          charts[date.iso8601] = {
            data: genders.to_a,
            title: _('Gender'),
            total: total,
          }
        end
      end
    end

    private def age_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          client_ids = Set.new
          data = age_names.keys.map { |k| [k, Set.new] }.to_h
          with_service_in_quarter(report_scope, date, population).
            joins(:client, :service_history_services).
            order(date: :desc). # Use the greatest age per person for the quarter
            where(shs_t[:date].between(date..date.end_of_quarter)). # hint for performance
            pluck(shs_t[:client_id], shs_t[:age]).
            each do |client_id, age|
              data[bucket_age(age)] << client_id unless client_ids.include?(client_id)
              client_ids << client_id
            end
          counts = data.values.map(&:count)
          # Set the total string for the middle before we do cleanup
          word = word_for(population)
          total = counts.sum
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end

          counts = enforce_min_threshold(counts, 'donut')
          ages = {}
          data.each.with_index do |(k, _), i|
            ages[age_name(k)] = counts[i]
          end

          charts[date.iso8601] = {
            data: ages.to_a,
            title: _('Age'),
            total: total,
          }
        end
      end
    end

    private def bucket_age(age)
      return :unknown if age.blank? || age.negative?
      return 0 if age < 18
      return 18 if age.between?(18, 24)
      return 25 if age.between?(25, 39)
      return 40 if age.between?(40, 49)
      return 50 if age.between?(50, 62)

      63
    end

    private def age_name(age)
      age_names[age]
    end

    private def age_names
      {
        0 => 'Under 18',
        18 => '18 to 24',
        25 => '25 to 39',
        40 => '40 to 49',
        50 => '50 to 62',
        63 => 'Over 63',
        unknown: 'Unknown',
      }.freeze
    end

    private def ethnicity_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = with_service_in_quarter(report_scope, date, population).
            joins(:client).
            group(c_t[:Ethnicity]).
            count.
            map do |e_id, count|
              # Force any unknown ethnicties to Unknown
              e_id = nil unless e_id.in?([0, 1])
              [
                ::HUD.ethnicity(e_id) || 'Unknown',
                count,
              ]
            end.to_h
          data['Unknown'] ||= 0
          counts = data.values
          # Set the total string for the middle before we do cleanup
          # Special case for families because we're actually showing ethnicity for all clients, not HoH
          word = if population == :adults_with_children
            word_for(nil)
          else
            word_for(population)
          end
          total = with_service_in_quarter(report_scope, date, population).select(:client_id).distinct.count
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end

          counts = enforce_min_threshold(counts, 'donut')

          ethnicities = {}
          data.each.with_index do |(k, _), i|
            ethnicities[k] = counts[i]
          end

          charts[date.iso8601] = {
            data: ethnicities.to_a,
            title: _('Ethnicity'),
            total: total,
          }
        end
      end
    end

    private def race_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          client_ids = Set.new
          client_cache = GrdaWarehouse::Hud::Client.new
          data = {}
          census_data = {}
          # Add census info
          ::HUD.races(multi_racial: true).each do |race_code, label|
            census_data[label] = 0
            data[::HUD.race(race_code, multi_racial: true)] ||= Set.new
            year = date.year
            full_pop = get_us_census_population(year: year)
            census_data[label] = get_us_census_population(race_code: race_code, year: year) / full_pop.to_f if full_pop&.positive?
          end
          all_destination_ids = with_service_in_quarter(report_scope, date, population).distinct.pluck(:client_id)
          with_service_in_quarter(report_scope, date, population).
            joins(:client).
            preload(:client).
            order(first_date_in_program: :desc). # Use the newest start
            find_each do |enrollment|
              client = enrollment.client
              race = client_cache.race_string(destination_id: client.id, scope_limit: client.class.where(id: all_destination_ids))
              data[::HUD.race(race, multi_racial: true)] << client.id unless client_ids.include?(client.id)
              client_ids << client.id
            end
          total_count = data.map { |_, ids| ids.count }.sum
          data = enforce_min_threshold(data, 'race')
          # Format:
          # [["Black or African American",38, 53],["White",53, 76],["Native Hawaiian or Other Pacific Islander",1, 12],["Multi-Racial",4, 10],["Asian",1, 5],["American Indian or Alaska Native",1, 1]]
          combined_data = data.map do |race, ids|
            label = if race == 'None'
              'Other or Unknown'
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

    private def get_us_census_population(race_code: 'All', year:)
      race_var = \
        case race_code
        when 'AmIndAKNative' then NATIVE_AMERICAN
        when 'Asian' then ASIAN
        when 'BlackAfAmerican' then BLACK
        when 'NativeHIPacific' then PACIFIC_ISLANDER
        when 'White' then WHITE
        when 'RaceNone' then OTHER_RACE
        when 'MultiRacial' then TWO_OR_MORE_RACES
        when 'All' then ALL_PEOPLE
        else
          raise "Invalid race code: #{race_code}"
        end

      results = geometries.map do |coc|
        coc.population(internal_names: race_var, year: year)
      end

      results.each do |result|
        if result.error
          Rails.logger.error "population error: #{result.msg}. Sum won't be right!"
          return nil
        elsif result.year != year
          Rails.logger.warn "Using #{result.year} instead of #{year}"
        end
      end

      results.map(&:val).sum
    end

    private def geometries
      @geometries ||= GrdaWarehouse::Shape::CoC.where(cocnum: coc_codes)
    end

    private def coc_codes
      scope = filter_for_range(report_scope)

      @coc_codes ||= begin
        result = scope.joins(project: :project_cocs).distinct.
          pluck(pc_t[:hud_coc_code], pc_t[:CoCCode]).map do |override, original|
            override.presence || original
          end
        reasonable_cocs_count = GrdaWarehouse::Shape::CoC.my_state.where(cocnum: result).count
        result = GrdaWarehouse::Shape::CoC.my_state.map(&:cocnum) if reasonable_cocs_count.zero? && !Rails.env.production?

        result
      end
    end

    private def household_chart(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = {}
          counted_clients = Set.new
          scope = with_service_in_quarter(report_scope.heads_of_households, date, population)
          scope.joins(client: :processed_service_history).
            preload(client: :processed_service_history).
            find_each do |enrollment|
              client = enrollment.client
              data[client_population(enrollment, date)] ||= 0
              data[client_population(enrollment, date)] += 1 unless counted_clients.include?(client.id)
              counted_clients << client.id
            end.to_h

          counts = data.values
          # Set the total string for the middle before we do cleanup
          word = word_for(:adults_with_children)
          total = counts.sum
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end

          counts = enforce_min_threshold(counts, 'donut')

          household_compositions = {}
          data.each.with_index do |(k, _), i|
            household_compositions[k] = counts[i]
          end
          charts[date.iso8601] = {
            data: household_compositions.to_a,
            title: _('Household Composition'),
            total: total,
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
      @adult_and_child_household_ids_by_date[date] ||= adult_and_child_household_ids(date)

      @adult_and_child_household_ids_by_date[date]
    end

    private def child_only_household_ids_by_date(date)
      @child_only_household_ids_by_date ||= {}
      @child_only_household_ids_by_date[date] ||= child_only_household_ids(date)

      @child_only_household_ids_by_date[date]
    end

    private def adult_and_child_household_ids(date)
      households = {}
      adult_and_child_households = []
      counted_ids = Set.new
      shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: date..date.end_of_quarter)
      report_scope.with_service_between(start_date: date, end_date: date.end_of_quarter, service_scope: shs_scope).
        joins(:service_history_services).
        merge(shs_scope).
        where.not(household_id: nil).
        order(shs_t[:date].asc).
        pluck(she_t[:household_id], shs_t[:age], shs_t[:client_id]).
        each do |hh_id, age, client_id|
          next if age.blank? || age.negative?

          key = [hh_id, client_id]
          households[hh_id] ||= []
          households[hh_id] << age unless counted_ids.include?(key)
          counted_ids << key
        end
      households.each do |hh_id, household|
        child_present = household.any? { |age| age < 18 }
        adult_present = household.any? { |age| age >= 18 }
        adult_and_child_households << hh_id if child_present && adult_present
      end
      adult_and_child_households
    end

    private def child_only_household_ids(date)
      households = {}
      child_only_households = []
      counted_ids = Set.new
      shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: date..date.end_of_quarter)
      report_scope.with_service_between(start_date: date, end_date: date.end_of_quarter, service_scope: shs_scope).
        joins(:service_history_services).
        merge(shs_scope).
        where.not(household_id: nil).
        order(shs_t[:date].asc).
        pluck(she_t[:household_id], shs_t[:age], shs_t[:client_id]).
        each do |hh_id, age, client_id|
          next if age.blank? || age.negative?

          key = [hh_id, client_id]
          households[hh_id] ||= []
          households[hh_id] << age unless counted_ids.include?(key)
          counted_ids << key
        end
      households.each do |hh_id, household|
        child_present = household.any? { |age| age < 18 }
        adult_present = household.any? { |age| age >= 18 }
        child_only_households << hh_id if child_present && ! adult_present
      end
      child_only_households
    end

    # count of clients vs counts of heads of household (spec says one per household)
    private def average_household_size(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          clients = client_count_for_date(date, population, :homeless)
          hohs = client_count_for_date(date, :hoh_from_adults_with_children, :homeless)

          charts[date.iso8601] = {
            data: (clients.to_f / hohs).round(1),
            title: _('Average Household Size'),
            total: total_for(with_service_in_quarter(report_scope, date, population), population),
          }
        end
      end
    end

    private def time_homeless(population)
      {}.tap do |charts|
        quarter_dates.each do |date|
          data = {
            'less than a month' => 0,
            'One to six months' => 0,
            'Six to twelve months' => 0,
            'More than one year' => 0,
          }
          counted_clients = Set.new
          with_service_in_quarter(report_scope, date, population).
            joins(client: :processed_service_history).
            preload(client: :processed_service_history).
            find_each do |enrollment|
              client = enrollment.client
              data[bucket_days(client.days_homeless(on_date: date))] += 1 unless counted_clients.include?(client.id)
              counted_clients << client.id
            end
          counts = data.values
          # Set the total string for the middle before we do cleanup
          word = word_for(population)
          total = counts.sum
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end

          counts = enforce_min_threshold(counts, 'donut')

          times = {}
          data.each.with_index do |(k, _), i|
            times[k] = counts[i]
          end
          charts[date.iso8601] = {
            data: times.to_a,
            title: _('Time Homeless'),
            total: total,
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
          data = {
            'less than a month' => 0,
            'One to six months' => 0,
            'Six to twelve months' => 0,
            'More than one year' => 0,
          }
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
              data[bucket_days(days)] += 1 unless counted_clients.include?(enrollment.client_id)
              counted_clients << enrollment.client_id
            end
          counts = data.values
          # Set the total string for the middle before we do cleanup
          word = word_for(population)
          total = counts.sum
          total = if total < 100
            "less than #{pluralize(100, word)}"
          else
            pluralize(number_with_delimiter(total), word)
          end

          counts = enforce_min_threshold(counts, 'donut')

          times = {}
          data.each.with_index do |(k, _), i|
            times[k] = counts[i]
          end
          charts[date.iso8601] = {
            data: times.to_a,
            title: _('Time in Project'),
            total: total,
          }
        end
      end
    end
  end
end
