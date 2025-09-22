###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# DEPRECATED: VersionOne is legacy code maintained only for displaying historical reports.
# New reports use VersionFour. Do not modify this class unless fixing critical bugs.
module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionThree < Base
    def run!
      progress_methods = [
        :start_report,
        :finish_report,
      ]
      progress_methods.each_with_index do |method, i|
        percent = ((i / progress_methods.size.to_f) * 100)
        percent = 0.01 if percent == 0
        Rails.logger.info "Starting #{method}, #{percent.round(2)}% complete"
        send(method)
        Rails.logger.info "Completed #{method}"
      end
    end

    def self.length_of_stay_buckets
      {
        # '0 days' => (0..0),
        # '1 week or less' => (1..6),
        # '1 month or less' => (7..30),
        '1 month or less' => (0..30),
        # '1 to 3 months'  => (31..90),
        # '3 to 6 months' => (91..180),
        '1 to 6 months' => (31..180),
        # '6 to 9 months' => (181..271),
        # '9 to 12 months' => (272..364),
        '6 to 12 months' => (181..364),
        # '1 year to 18 months' => (365..545),
        # '18 months - 2 years' => (546..729),
        # '2 - 5 years' => (730..1825),
        # '5 years or more' => (1826..1.0/0),
        '12 months or greater' => (365..Float::INFINITY),
      }
    end

    # View related
    def total_client_count
      @total_client_count ||= begin
                                report['total_clients']
                              rescue StandardError
                                0
                              end
    end

    def no_clients?
      total_client_count == 0
    end

    def no_issues
      'No issues'
    end

    def describe_served_percentage
      if report['total_active_clients'] / total_client_count < (completeness_goal / 100)
        'Percent of enrolled clients with a service in the reporting period below acceptable threshold.'
      else
        no_issues
      end
    end

    def describe_bed_utilization
      if report['bed_utilization_totals']['counts']['average_daily_percentage'] < completeness_goal
        'Bed utilization below acceptable threshold'
      elsif report['bed_utilization_totals']['counts']['average_daily_percentage'] > excess_goal
        'Bed utilization above acceptable threshold'
      else
        no_issues
      end
    end

    def describe_unit_utilization
      if report['unit_utilization_totals']['counts']['average_daily_percentage'] < completeness_goal
        'Unit utilization below acceptable threshold'
      elsif report['unit_utilization_totals']['counts']['average_daily_percentage'] > excess_goal
        'Unit utilization above acceptable threshold'
      else
        no_issues
      end
    end

    def describe_descriptor_completeness
      issues = []
      issues << 'Missing Bed Inventory' if report['bed_utilization_totals']['counts']['capacity'].blank? || report['bed_utilization_totals']['counts']['capacity'] == 0
      issues << 'Missing Unit Inventory' if report['unit_utilization_totals']['counts']['capacity'].blank? || report['unit_utilization_totals']['counts']['capacity'] == 0
      issues << 'Missing CoC Code' if report['coc_code'].blank?
      issues << 'Missing Funder' if report['grant_id'].blank?
      issues << 'Missing Geocode' if report['geocode'].blank?
      issues << 'Missing Geography Type' if report['geography_type'].blank?
      issues << 'Missing Housing Type' if report['housing_type'].blank?
      issues << 'Missing Information Date' if report['information_date'].blank?
      issues << 'Missing Operation Start Date' if report['operating_start_date'].blank?
      issues << 'Missing Project Type' if report['coc_program_component'].blank?
      issues << no_issues if issues.empty?
      return issues
    end

    def describe_data_completeness
      issues = []
      issues << 'High Missing Rate - Name' if report['missing_name_percent'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Name' if report['refused_name_percent'] > mininum_completeness_threshold
      issues << 'High Missing Rate - SSN' if report['missing_ssn_percent'] > mininum_completeness_threshold
      issues << 'High Refused Rate - SSN' if report['refused_ssn_percent'] > mininum_completeness_threshold
      issues << 'High Missing Rate - DOB' if report['missing_dob_percent'] > mininum_completeness_threshold
      issues << 'High Refused Rate - DOB' if report['refused_dob_percent'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Veteran' if report['missing_veteran_percent'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Veteran' if report['refused_veteran_percent'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Ethnicity' if report['missing_ethnicity_percent'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Ethnicity' if report['refused_ethnicity_percent'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Race' if report['missing_race_percent'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Race' if report['refused_race_percent'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Disabling Condition' if report['missing_disabling_condition_percentage'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Disabling Condition' if report['refused_disabling_condition_percentage'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Prior Living Situation' if report['missing_prior_living_situation_percentage'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Prior Living Situation' if report['refused_prior_living_situation_percentage'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Destination' if report['missing_destination_percentage'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Destination' if report['refused_destination_percentage'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Income at Entry' if report['missing_income_at_entry_percentage'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Income At Entry' if report['refused_income_at_entry_percentage'] > mininum_completeness_threshold
      issues << 'High Missing Rate - Income at Exit' if report['missing_income_at_exit_percentage'] > mininum_completeness_threshold
      issues << 'High Refused Rate - Income At Exit' if report['refused_income_at_entry_percentage'] > mininum_completeness_threshold
      issues << no_issues if issues.empty?
      return issues
    end

    def describe_timeliness
      issues = []
      # if we have more than one project, use average, otherwise, use the project
      key = 'Average'
      key = project.ProjectName if projects.count == 1
      # This is nasty, but for billboard we save these as a 3 element array
      # the second element contains the actual value
      issues << 'Time to enter exceeds acceptable threshold' if report['average_timeliness_of_entry']['data'][key].present? && report['average_timeliness_of_entry']['data'][key].second > timeliness_goal
      issues << 'Time to exit exceeds acceptable threshold' if report['average_timeliness_of_exit']['data'][key].present? && report['average_timeliness_of_exit']['data'][key].second > timeliness_goal

      issues << no_issues if issues.empty?
      return issues
    end

    def describe_timeliness_entry_average_value
      key = 'Average'
      key = project.ProjectName if projects.count == 1
      # This is nasty, but for billboard we save these as a 3 element array
      # the second element contains the actual value
      report['average_timeliness_of_entry']['data'].try(:[], key)&.second
    end

    def describe_timeliness_exit_average_value
      key = 'Average'
      key = project.ProjectName if projects.count == 1
      # This is nasty, but for billboard we save these as a 3 element array
      # the second element contains the actual value
      report['average_timeliness_of_exit']['data'].try(:[], key)&.second
    end

    # End view related

    def completeness_goal
      90
    end

    def excess_goal
      105
    end

    def mininum_completeness_threshold
      100 - completeness_goal
    end

    def timeliness_goal
      14 # days
    end

    def income_increase_goal
      75
    end

    def ph_destination_increase_goal
      60
    end

    def all_serve_same_household_type?
      @all_serve_same_household_type ||= projects.map(&:inventories).map { |inventories| inventories.map(&:HouseholdType) }.flatten.uniq.count == 1
    end

    def enrollment_data_for_project(project)
      data = service_history_enrollment_scope.
        open_between(start_date: start, end_date: self.end).
        in_project(project).
        joins(:project, :client, :enrollment).
        pluck(*enrollment_columns.values)
      data.map do |row|
        Hash[enrollment_columns.keys.zip(row)]
      end
    end

    def self.completeness_field_names
      {
        # first_name: "First Name",
        # last_name: "Last Name",
        name: 'Name',
        dob: 'DOB',
        ssn: 'SSN',
        race: 'Race',
        ethnicity: 'Ethnicity',
        gender: 'Gender',
        veteran: 'Veteran Status',
        disabling_condition: 'Disabling Condition',
        prior_living_situation: 'Living Situation',
        income_at_entry: 'Income At Entry',
        income_at_exit: 'Income At Exit',
        destination: 'Destination',
      }
    end

    def completeness_percentages(data)
      result = Vector.elements(Array.new(self.class.completeness_field_names.values.size, 100))
      result -= Vector.elements(incompleteness_percentages('missing', data))
      result -= Vector.elements(incompleteness_percentages('refused', data))
      result -= Vector.elements(incompleteness_percentages('unknown', data))
      result -= Vector.elements(no_interview_percentages(data))
      return result.to_a
    end

    def missing_or_dont_know_percentages(data)
      result = Vector.elements(incompleteness_percentages('refused', data))
      result += Vector.elements(incompleteness_percentages('unknown', data))
      return result.to_a
    end

    def incompleteness_percentages(prefix, data)
      result = []
      self.class.completeness_field_names.keys.each do |key|
        result << data["#{prefix}_#{key}_percentage"].round
      end
      return result
    end

    def no_interview_percentages(data)
      result = []
      self.class.completeness_field_names.keys.each do |key|
        if key == :destination
          result << data['no_interview_destination_percentage'].round
        else
          result << 0
        end
      end
      return result
    end

    def household_support(household_ids)
      hoh_columns = {
        client_id: c_t[:id].to_sql,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
        enrollment_id: she_t[:id].to_sql,
        destination: she_t[:destination].to_sql,
      }

      hohs = service_history_enrollment_scope.
        where(household_id: household_ids).
        joins(:client).
        distinct.
        pluck(*hoh_columns.values).map do |row|
        Hash[hoh_columns.keys.zip(row)]
      end

      enrollment_ids = hohs.map { |m| m[:enrollment_id] }
      # min_enrollment_date = hohs.map{|c| c[:first_date_in_program]}.min
      max_exit_date = (hohs.map { |c| c[:last_date_in_program] }.compact + [Date.current]).max
      max_dates = max_dates_served(enrollment_ids, range: (start..max_exit_date))

      hohs.each do |hoh|
        dest = hoh[:destination].to_i
        hoh[:destination_text] = "#{dest}: #{HudHelper.util('legacy').destination(dest)}" if dest != 0

        hoh[:most_recent_service] = max_dates[hoh[:enrollment_id]] || 'Before report start'
        hoh.delete(:enrollment_id)
      end
      {
        headers: ['Client ID', 'First Name', 'Last Name', 'First Date In Program', 'Last Date In Program', 'Most Recent Service', 'Destination'],
        counts: hohs.map do |hoh|
          [
            hoh[:client_id], hoh[:first_name], hoh[:last_name], hoh[:first_date_in_program],
            hoh[:last_date_in_program], hoh[:most_recent_service], hoh[:destination_text]
          ]
        end,
      }
    end

    def transitioning_household_support(households)
      hohs = households.values.deep_dup.map(&:first)

      enrollment_ids = hohs.map { |m| m[:enrollment_id] }
      # min_enrollment_date = hohs.map{|c| c[:first_date_in_program]}.min
      max_exit_date = (hohs.map { |c| c[:last_date_in_program] }.compact + [Date.current]).max
      max_dates = max_dates_served(enrollment_ids, range: (start..max_exit_date))

      hohs.each do |hoh|
        dest = hoh[:destination].to_i
        hoh[:destination_text] = "#{dest}: #{HudHelper.util('legacy').destination(dest)}" if dest != 0
        hoh[:most_recent_service] = max_dates[hoh[:enrollment_id]] || 'Before report start'
        hoh.delete(:enrollment_id)
      end
      {
        headers: ['Client ID', 'First Name', 'Last Name', 'First Date In Program', 'Last Date In Program', 'Most Recent Service', 'Destination'],
        counts: hohs.map do |hoh|
          [
            hoh[:id], hoh[:first_name], hoh[:last_name], hoh[:first_date_in_program],
            hoh[:last_date_in_program], hoh[:most_recent_service], hoh[:destination_text]
          ]
        end,
      }
    end

    def self.missing_refused_names
      {
        first_name: ['Client ID', 'First Name', 'Last Name', 'Name Data Quality'],
        last_name: ['Client ID', 'First Name', 'Last Name', 'Name Data Quality'],
        name: ['Client ID', 'First Name', 'Last Name', 'Name Data Quality'],
        ssn: ['Client ID', 'First Name', 'Last Name', 'SSN', 'SSN Quality'],
        dob: ['Client ID', 'First Name', 'Last Name', 'DOB', 'DOB Quality'],
        veteran: ['Client ID', 'First Name', 'Last Name', 'Veteran Status'],
        ethnicity: ['Client ID', 'First Name', 'Last Name', 'Ethnicity'],
        race: ['Client ID', 'First Name', 'Last Name', 'Race None', 'AmIndAKNative', 'Asian', 'Black or African American', 'Native HI Other Pacific', 'White'],
        gender: ['Client ID', 'First Name', 'Last Name', 'Gender'],
        disabling_condition: ['Client ID', 'First Name', 'Last Name', 'Disability Type', 'Disability Response'],
        prior_living_situation: ['Client ID', 'First Name', 'Last Name', 'Prior Living Situation'],
        destination: ['Client ID', 'First Name', 'Last Name', 'Destination'],
        no_interview_destination: ['Client ID', 'First Name', 'Last Name', 'Destination'],
        # last_permanent_zip: ['Client ID', 'First Name', 'Last Name', 'Last Permanent Zip'],
        income_at_entry: ['Client ID', 'First Name', 'Last Name'],
        income_at_exit: ['Client ID', 'First Name', 'Last Name'],
      }
    end

    def base_colums_for_support(enrollment)
      [
        enrollment[:id],
        enrollment[:first_name],
        enrollment[:last_name],
      ]
    end

    def columns_for_income_at_entry(enrollment)
      base_colums_for_support(enrollment)
    end

    def columns_for_income_at_exit(enrollment)
      base_colums_for_support(enrollment)
    end

    def columns_for_missing_support(enrollment)
      base_colums_for_support(enrollment) + [
        enrollment[:name_data_quality],
        enrollment[:ssn],
        enrollment[:ssn_data_quality],
        enrollment[:dob],
        enrollment[:dob_data_quality],
      ]
    end

    def columns_for_destination_support(enrollment)
      base_colums_for_support(enrollment) + [
        enrollment[:destination],
      ]
    end

    # this may return multiple rows per client and must be added to the support
    # stack with += instead of <<
    def columns_for_disabling_condition_support(enrollment, disabilities, value)
      if disabilities.blank?
        [
          base_colums_for_support(enrollment) + [
            nil,
            nil,
          ],
        ]
      else
        disabilities.select do |dis|
          dis[:disability_response].to_i == value
        end.map do |dis|
          base_colums_for_support(enrollment) + [
            HudHelper.util('legacy').disability_type(dis[:disability_type]),
            dis[:disability_response],
          ]
        end
      end
    end

    def columns_for_gender_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:gender],
      ]
    end

    def columns_for_veteran_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:veteran_status],
      ]
    end

    def columns_for_first_name_support enrollment
      base_colums_for_support(enrollment) + [
        99, # Data Quality Code "Data Not Collected", There is no DQ for first name, field added to keep shape consistent
      ]
    end

    def columns_for_last_name_support enrollment
      base_colums_for_support(enrollment) + [
        99, # Data Quality Code "Data Not Collected", There is no DQ for last name, field added to keep shape consistent
      ]
    end

    def columns_for_name_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:name_data_quality],
      ]
    end

    def columns_for_ssn_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:ssn],
        enrollment[:ssn_data_quality],
      ]
    end

    def columns_for_dob_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:dob],
        enrollment[:dob_data_quality],
      ]
    end

    def columns_for_ethnicity_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:ethnicity],
      ]
    end

    def columns_for_residence_prior_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:residence_prior],
      ]
    end

    # def columns_for_last_permanent_zip_support enrollment
    #   base_colums_for_support(enrollment) + [
    #     enrollment[:last_permanent_zip]
    #   ]
    # end

    def columns_for_race_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:race_none],
        enrollment[:am_ind_ak_native],
        enrollment[:asian],
        enrollment[:black_af_american],
        enrollment[:native_hi_other_pacific],
        enrollment[:white],
      ]
    end

    def self.bed_utilization_attributes
      [
        :average_daily,
      ]
    end

    def bed_utilization_client_columns
      {
        client_id: :client_id,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        date: shs_t[:date].to_sql,
      }
    end

    def unit_utilization_client_columns
      {
        client_id: :client_id,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        date: shs_t[:date].to_sql,
        household_id: she_t[:household_id].to_sql,
      }
    end

    def self.unit_utilization_attributes
      [
        :average_daily,
      ]
    end

    def universal_element_client_header
      @universal_element_client_header ||= ['Client ID', 'First Name', 'Last Name', 'First Date In Program', 'Last Date In Program', 'Most Recent Service', 'Destination']
    end

    def universal_element_client_counts(clients)
      clients.map do |m|
        [
          m[:destination_id],
          m[:first_name],
          m[:last_name],
          m[:first_date_in_program],
          m[:last_date_in_program],
          m[:most_recent_service],
          m[:destination].present? ? "#{m[:destination]}: #{HudHelper.util('legacy').destination(m[:destination].to_i)}" : '',
        ]
      end
    end

    def problem_support_details(counts, problem, field)
      {
        headers: ['Client ID', 'Problem', 'Field'],
        counts: counts.map { |m| [m, problem, field] },
      }
    end

    def income_support_header
      ['Client ID', 'First Name', 'Last Name', 'Project Name', '% Change']
    end

    def income_support(client_id, changes)
      data = changes[client_id]
      [client_id, data[:first_name], data[:last_name], data[:project_name], data[:change]]
    end

    def income_increase(current_values, last_earned_income, first_earned_income, assessment)
      result = current_values || {}

      enrollment = enrollments[assessment[:client_id]].detect { |e| e[:enrollment_id] == assessment[:enrollment_id] }
      result[:first_name] ||= enrollment[:first_name]
      result[:last_name] ||= enrollment[:last_name]
      result[:project_name] ||= enrollment[:project_name]

      if first_earned_income && first_earned_income > 0
        increase = last_earned_income - first_earned_income
        change = ((increase.to_f / first_earned_income) * 100).round
        result[:change] = [change, result[:change]].compact.max
      else
        result[:change] = result[:change] || 'no income at start'
      end
      result
    end

    def increased_twenty_percent?(last_earned_income, first_earned_income)
      last_earned_income >= first_earned_income * 1.2
    end

    def report_columns
      {
        total_clients: {
          title: 'Clients included',
        },
        total_leavers: {
          title: 'Leavers',
        },
        agency_name: {
          title: 'Agency name',
        },
        project_name: {
          title: 'Project name(s)',
        },
        monitoring_date_range: {
          title: 'Operating year (Funder start date and end date)',
        },
        monitoring_date_range_present: {
          title: 'Operating year present?',
          callback: :boolean,
        },
        grant_id: {
          title: 'Grant identification #',
        },
        coc_program_component: {
          title: 'CoC program component (project type)',
        },
        target_population: {
          title: 'Target population',
        },
        entering_required_data: {
          title: 'Is the agency entering the required data/descriptor touch-points into HMIS for this project?',
          callback: :boolean,
        },
        bed_coverage: {
          title: 'Bed coverage',
        },
        bed_coverage_percent: {
          title: 'Bed coverage',
          callback: :percent,
        },
        # missing_name_percent: {
        #   title: 'Missing names',
        #   callback: :percent,
        # },
        # missing_ssn_percent: {
        #   title: 'Missing SSN',
        #   callback: :percent,
        # },
        # missing_dob_percent: {
        #   title: 'Missing DOB',
        #   callback: :percent,
        # },
        # missing_veteran_percent: {
        #   title: 'Missing veteran status',
        #   callback: :percent,
        # },
        # missing_ethnicity_percent: {
        #   title: 'Missing ethnicity',
        #   callback: :percent,
        # },
        # missing_race_percent: {
        #   title: 'Missing race',
        #   callback: :percent,
        # },
        # missing_gender_percent: {
        #   title: 'Missing gender',
        #   callback: :percent,
        # },
        # missing_disabling_condition_percentage: {
        #   title: 'Missing disabling condition',
        #   callback: :percent
        # },
        # missing_prior_living_percentage: {
        #   title: 'Missing prior living',
        #   callback: :percent
        # },
        # missing_destination_percentage: {
        #   title: 'Missing destination',
        #   callback: :percent
        # },
        # refused_name_percent: {
        #   title: 'Refused name',
        #   callback: :percent,
        # },
        # refused_ssn_percent: {
        #   title: 'Refused SSN',
        #   callback: :percent,
        # },
        # refused_dob_percent: {
        #   title: 'Refused DOB',
        #   callback: :percent,
        # },
        # refused_veteran_percent: {
        #   title: 'Refused veteran status',
        #   callback: :percent,
        # },
        # refused_ethnicity_percent: {
        #   title: 'Refused ethnicity',
        #   callback: :percent,
        # },
        # refused_race_percent: {
        #   title: 'Refused race',
        #   callback: :percent,
        # },
        # refused_gender_percent: {
        #   title: 'Refused gender',
        #   callback: :percent,
        # },
        # refused_disabling_condition_percentage: {
        #   title: 'Refused disabling condition',
        #   callback: :percent
        # },
        # refused_prior_living_percentage: {
        #   title: 'Refused prior living',
        #   callback: :percent
        # },
        # refused_destination_percentage: {
        #   title: 'Refused destination',
        #   callback: :percent
        # },
        meets_dq_benchmark: {
          title: "Meets DQ Benchmark (all missing/refused < #{mininum_completeness_threshold}%)",
          callback: :boolean,
        },
        one_year_enrollments: {
          title: 'Enrollments lasting 12 or more months',
        },
        one_year_enrollments_percentage: {
          title: 'Clients with enrollments lasting 12 or more months',
          callback: :percent,
        },
        ph_destinations: {
          title: 'Leavers who exited to PH',
        },
        ph_destinations_percentage: {
          title: 'Percentage of leavers who exited to PH',
        },
        increased_earned: {
          title: 'Clients with increased or retained earned income',
        },
        increased_earned_percentage: {
          title: 'Percentage of clients who had increased or retained  earned income',
          callback: :percent,
        },
        increased_non_cash: {
          title: 'Clients with increased or retained  non-cash income',
        },
        increased_non_cash_percentage: {
          title: 'Percentage of clients who had increased or retained  non-cash income',
          callback: :percent,
        },
        increased_overall: {
          title: 'Clients with increased or retained  overall income',
        },
        increased_overall_percentage: {
          title: 'Percentage of clients who had increased or retained  total income',
          callback: :percent,
        },
        services_provided: {
          title: 'Number of service events',
        },
        days_of_service: {
          title: 'Number of days in selected range',
        },
        average_daily_usage: {
          title: 'Average daily usage',
        },
        average_stay_length: {
          title: 'Average stay length',
          callback: :days,
        },
        capacity_percentage: {
          title: 'Percentage of beds in use, on average',
          callback: :percent,
        },
      }
    end

    def filter
      @filter ||= ::Filters::DateRange.new(start: start, end: self.end)
    end

    def active_clients
      @active_clients ||= service_history_enrollment_scope.
        service_within_date_range(start_date: start, end_date: self.end).
        joins(:client, :project).
        where(Project: { id: projects.map(&:id) }).
        distinct.
        pluck(*client_columns.values.map { |column| Arel.sql(column) }).
        map do |row|
        Hash[client_columns.keys.zip(row)]
      end
    end

    def enterers
      entries.keys
    end

    # Enrollments opened during report range
    def entries
      @entries ||= begin
        entries = {}
        enrollments.each do |client_id, client_enrollments|
          client_enrollments.each do |enrollment|
            if enrollment[:first_date_in_program].present? && enrollment[:first_date_in_program] >= start
              entries[client_id] ||= []
              entries[client_id] << enrollment
            end
          end
        end
        entries
      end
    end

    # Enrollments closed during the report range
    def exits
      @exits ||= begin
        exits = {}
        enrollments.each do |client_id, client_enrollments|
          client_enrollments.each do |enrollment|
            # we don't need to verify that exit is after report start since the enrollment must overlap the report range
            if enrollment[:last_date_in_program].present? && enrollment[:last_date_in_program] <= self.end
              exits[client_id] ||= []
              exits[client_id] << enrollment
            end
          end
        end
        exits
      end
    end

    def households
      @households ||= service_history_enrollment_scope.
        open_between(start_date: start, end_date: self.end).
        in_project(projects.map(&:id)).
        distinct.
        pluck(:household_id)
    end

    def entering_households
      @entering_households ||= begin
        entries = {}
        enrollments.each do |_client_id, client_enrollments|
          client_enrollments.each do |enrollment|
            next unless enrollment[:first_date_in_program].present? && enrollment[:first_date_in_program] >= start

            household = enrollment[:household_id]
            entries[household] ||= []
            entries[household] << enrollment
          end
        end
        entries
      end
    end

    def exiting_households
      @exiting_households ||= begin
        exits = {}
        enrollments.each do |_client_id, client_enrollments|
          client_enrollments.each do |enrollment|
            next unless enrollment[:last_date_in_program].present? && enrollment[:last_date_in_program] <= self.end

            household = enrollment[:household_id]
            exits[household] ||= []
            exits[household] << enrollment
          end
        end
        exits
      end
    end

    # At entry: data_collection_stage = 1
    # At exit: data_collection_stage = 3
    def missing_income(source_client_id, enrollment, data_collection_stage:)
      incomes = income_assessment_at_stage_for(
        source_client_id: source_client_id,
        enrollment_id: enrollment[:enrollment_id],
        data_collection_stage: data_collection_stage,
      )

      return true unless incomes.present?

      incomes.each do |income|
        return true if income[:IncomeFromAnySource] == 99 || # Data Not Collected
          (income[:TotalMonthlyIncome].nil? && income[:IncomeFromAnySource] == 0) ||
          (income[:TotalMonthlyIncome].nil? && income[:IncomeFromAnySource] == 1)
      end
      return false
    end

    def refused_income(source_client_id, enrollment, data_collection_stage:)
      incomes = income_assessment_at_stage_for(
        source_client_id: source_client_id,
        enrollment_id: enrollment[:enrollment_id],
        data_collection_stage: data_collection_stage,
      )

      if incomes.present?
        incomes.each do |income|
          return true if income[:IncomeFromAnySource] == 9 # Refused
        end
      end
      return false
    end
  end
end
