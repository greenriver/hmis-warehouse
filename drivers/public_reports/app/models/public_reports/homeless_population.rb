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
      }
    end

    private def pit_chart(population)
      title = case population
      when :overall
        _('People Experiencing Homelessness')
      when :housed
        _('People Housed')
      when :individuals
        _('Individuals')
      when :adults_with_children
        _('Families')
      when :veterans
        _('Veterans')
      end
      {
        data: pit_chart_data(population, title),
        title: title,
      }
    end

    private def pit_chart_data(population, title)
      x = ['x']
      y = [title]
      pit_counts(population).each do |date, count|
        x << date
        y << count
      end
      [x, y].to_json
    end

    private def pit_counts(population)
      quarter_dates.map do |date|
        [
          date,
          client_count_for_date(date, population),
        ]
      end
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
            charts[date] = {
              data: {
                rapid_rehousing: with_service_in_quarter(report_scope, date, population).in_project_type(13).select(:client_id).distinct.count,
                permanent_housing: with_service_in_quarter(report_scope, date, population).in_project_type([3, 9, 10]).select(:client_id).distinct.count,
              },
              title: _('Type of Housing'),
            }
          when :homeless
            charts[date] = {
              data: {
                sheltered: with_service_in_quarter(report_scope, date, population).homeless_sheltered.select(:client_id).distinct.count,
                unsheltered: with_service_in_quarter(report_scope, date, population).homeless_unsheltered.select(:client_id).distinct.count,
              },
              title: _('Where People are Staying'),
            }
          else
            charts[date] = {
              data: {
                homeless: with_service_in_quarter(report_scope, date, population).homeless.select(:client_id).distinct.count,
                housed: with_service_in_quarter(report_scope, date, population).residential_non_homeless.select(:client_id).distinct.count,
              },
              title: _('Homeless vs Housed'),
            }
          end
        end
      end
    end

    private def with_service_in_quarter(scope, date, population)
      scope_for(population, date, scope).with_service_between(start_date: date, end_date: date.end_of_quarter)
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
          charts[date] = {
            data: with_service_in_quarter(report_scope, date, population).
              joins(:client).
              group(c_t[:Gender]).
              count.
              map do |gender_id, count|
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
          ages = {
            0 => Set.new,
            18 => Set.new,
            65 => Set.new,
            unknown: Set.new,
          }
          with_service_in_quarter(report_scope, date, population).
            joins(:client).
            pluck(she_t[:client_id], shs_t[:age]).
            sort_by(&:last).
            each do |client_id, age|
              ages[bucket_age(age)] << client_id unless client_ids.include?(client_id)
            end
          charts[date] = {
            data: ages.map { |age, ids| [age, ids.count] },
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
  end
end
