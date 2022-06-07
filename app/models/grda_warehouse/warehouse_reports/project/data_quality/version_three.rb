###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionThree < Base
    def run!
      progress_methods = [
        :start_report,
        :set_project_metadata,
        :set_bed_coverage_data,
        :calculate_missing_universal_elements,
        :add_missing_enrollment_elements,
        :add_agency_entering_data,
        :add_length_of_stay,
        :destination_ph,
        :add_income_answers,
        :add_capacity_answers,
        :meets_data_quality_benchmark,
        :add_bed_utilization,
        :add_unit_utilization,
        :add_missing_values,
        :add_enrolled_length_of_stay,
        :add_clients_dob_enrollment_date,
        :add_night_by_night_missing,
        :add_service_after_close,
        :add_individuals_at_family_projects,
        :add_families_at_individual_projects,
        :add_enrollments_with_no_service,
        :add_data_timeliness,
        :add_households,
        :finish_report,
      ]
      progress_methods.each_with_index do |method, i|
        percent = ((i/progress_methods.size.to_f)* 100)
        percent = 0.01 if percent == 0
        Rails.logger.info "Starting #{method}, #{percent.round(2)}% complete"
        self.send(method)
        Rails.logger.info "Completed #{method}"
      end
    end

    def self.length_of_stay_buckets
      {
          # '0 days' => (0..0),
          # '1 week or less' => (1..6),
          # '1 month or less' => (7..30),
          '1 month or less' => (0..30),
          #'1 to 3 months'  => (31..90),
          #'3 to 6 months' => (91..180),
          '1 to 6 months' => (31..180),
          #'6 to 9 months' => (181..271),
          #'9 to 12 months' => (272..364),
          '6 to 12 months' => (181..364),
          #'1 year to 18 months' => (365..545),
          #'18 months - 2 years' => (546..729),
          #'2 - 5 years' => (730..1825),
          #'5 years or more' => (1826..1.0/0),
          '12 months or greater' => (365..Float::INFINITY),
      }
    end

    # View related
    def total_client_count
      @total_client_count ||= report['total_clients'] rescue 0
    end

    def no_clients?
      total_client_count == 0
    end

    def no_issues
      'No issues'
    end

    def describe_served_percentage
      if report['total_active_clients'] / total_client_count < (completeness_goal/100)
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
      if report['bed_utilization_totals']['counts']['capacity'].blank? || report['bed_utilization_totals']['counts']['capacity'] == 0
        issues << "Missing Bed Inventory"
      end
      if report['unit_utilization_totals']['counts']['capacity'].blank? || report['unit_utilization_totals']['counts']['capacity'] == 0
        issues << "Missing Unit Inventory"
      end
      if report['coc_code'].blank?
        issues << "Missing CoC Code"
      end
      if report['grant_id'].blank?
        issues << "Missing Funder"
      end
      if report['geocode'].blank?
        issues << "Missing Geocode"
      end
      if report['geography_type'].blank?
        issues << "Missing Geography Type"
      end
      if report['housing_type'].blank?
        issues << "Missing Housing Type"
      end
      if report['information_date'].blank?
        issues << "Missing Information Date"
      end
      if report['operating_start_date'].blank?
        issues << "Missing Operation Start Date"
      end
      if report['coc_program_component'].blank?
        issues << "Missing Project Type"
      end
      issues << no_issues if issues.empty?
      return issues
    end

    def describe_data_completeness
      issues = []
      if report['missing_name_percent'] > mininum_completeness_threshold
        issues << "High Missing Rate - Name"
      end
      if report['refused_name_percent'] > mininum_completeness_threshold
        issues << "High Refused Rate - Name"
      end
      if report['missing_ssn_percent'] > mininum_completeness_threshold
        issues << "High Missing Rate - SSN"
      end
      if report['refused_ssn_percent'] > mininum_completeness_threshold
        issues << "High Refused Rate - SSN"
      end
      if report['missing_dob_percent'] > mininum_completeness_threshold
        issues << "High Missing Rate - DOB"
      end
      if report['refused_dob_percent'] > mininum_completeness_threshold
        issues << "High Refused Rate - DOB"
      end
      if report['missing_veteran_percent'] > mininum_completeness_threshold
        issues << "High Missing Rate - Veteran"
      end
      if report['refused_veteran_percent'] > mininum_completeness_threshold
        issues << "High Refused Rate - Veteran"
      end
      if report['missing_ethnicity_percent'] > mininum_completeness_threshold
        issues << "High Missing Rate - Ethnicity"
      end
      if report['refused_ethnicity_percent'] > mininum_completeness_threshold
        issues << "High Refused Rate - Ethnicity"
      end
      if report['missing_race_percent'] > mininum_completeness_threshold
        issues << "High Missing Rate - Race"
      end
      if report['refused_race_percent'] > mininum_completeness_threshold
        issues << "High Refused Rate - Race"
      end
      if report['missing_disabling_condition_percentage'] > mininum_completeness_threshold
        issues << "High Missing Rate - Disabling Condition"
      end
      if report['refused_disabling_condition_percentage'] > mininum_completeness_threshold
        issues << "High Refused Rate - Disabling Condition"
      end
      if report['missing_prior_living_situation_percentage'] > mininum_completeness_threshold
        issues << "High Missing Rate - Prior Living Situation"
      end
      if report['refused_prior_living_situation_percentage'] > mininum_completeness_threshold
        issues << "High Refused Rate - Prior Living Situation"
      end
      if report['missing_destination_percentage'] > mininum_completeness_threshold
        issues << "High Missing Rate - Destination"
      end
      if report['refused_destination_percentage'] > mininum_completeness_threshold
        issues << "High Refused Rate - Destination"
      end
      if report['missing_income_at_entry_percentage'] > mininum_completeness_threshold
        issues << "High Missing Rate - Income at Entry"
      end
      if report['refused_income_at_entry_percentage'] > mininum_completeness_threshold
        issues << "High Refused Rate - Income At Entry"
      end
      if report['missing_income_at_exit_percentage'] > mininum_completeness_threshold
        issues << "High Missing Rate - Income at Exit"
      end
      if report['refused_income_at_entry_percentage'] > mininum_completeness_threshold
        issues << "High Refused Rate - Income At Exit"
      end
      issues << no_issues if issues.empty?
      return issues
    end

    def describe_timeliness
      issues = []
      # if we have more than one project, use average, otherwise, use the project
      key = 'Average'
      if projects.count == 1
        key = project.ProjectName
      end
      # This is nasty, but for billboard we save these as a 3 element array
      # the second element contains the actual value
      if report['average_timeliness_of_entry']['data'][key].present? && report['average_timeliness_of_entry']['data'][key].second > timeliness_goal
        issues << "Time to enter exceeds acceptable threshold"
      end
      if report['average_timeliness_of_exit']['data'][key].present? && report['average_timeliness_of_exit']['data'][key].second > timeliness_goal
        issues << "Time to exit exceeds acceptable threshold"
      end

      issues << no_issues if issues.empty?
      return issues
    end

    def describe_timeliness_entry_average_value
      key = 'Average'
      if projects.count == 1
        key = project.ProjectName
      end
      # This is nasty, but for billboard we save these as a 3 element array
      # the second element contains the actual value
      report['average_timeliness_of_entry']['data'].try(:[], key)&.second
    end

    def describe_timeliness_exit_average_value
      key = 'Average'
      if projects.count == 1
        key = project.ProjectName
      end
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
      @all_serve_same_household_type ||= projects.map(&:inventories).map{|inventories| inventories.map(&:HouseholdType)}.flatten.uniq.count == 1
    end


    def set_project_metadata
      agency_names = projects.map(&:organization).map(&:OrganizationName).compact
      project_names = projects.map(&:ProjectName)
      coc_codes = projects.flat_map do |project|
        project.project_cocs.map(&:CoCCode)
      end.uniq
      geocodes = projects.flat_map do |project|
        project.geographies.map(&:Geocode)
      end.uniq
      geography_types = projects.flat_map do |project|
        project.geographies.map do |geography|
          ::HUD.geography_type(geography.GeographyType)
        end
      end.uniq
      housing_types = projects.flat_map do |project|
        ::HUD.housing_type(project.HousingType)
      end.uniq
      information_dates = projects.flat_map do |project|
        project.inventories.map(&:InformationDate)
      end.uniq
      start_dates = projects.map(&:OperatingStartDate).uniq
      coc_program_components = projects.map do |project|
        ::HUD.project_type(project.ProjectType)
      end
      target_populations = projects.map do |project|
        ::HUD.target_population(project.TargetPopulation) || nil
      end.compact

      monitoring_ranges = []
      monitoring_date_range_present = false
      grant_ids = []
      projects.flat_map(&:funders).each do |funder|
        monitoring_ranges << "#{funder&.StartDate} - #{funder&.EndDate}" if funder.StartDate.present? || funder.EndDate.present?
        monitoring_date_range_present = true if funder&.StartDate.present? && funder&.EndDate.present?
        grant_ids << funder.GrantID if funder.GrantID.present?
      end

      add_answers({
        agency_name: agency_names.join(', '),
        project_name: project_names.join(', '),
        coc_code: coc_codes.join(', '),
        geocode: geocodes.join(', '),
        geography_type: geography_types.join(', '),
        housing_type: housing_types.join(', '),
        information_date: information_dates.join(', '),
        operating_start_date: start_dates.join(', '),
        monitoring_date_range: monitoring_ranges.join(', '),
        monitoring_date_range_present: monitoring_date_range_present,
        # funding_year: funder.operating_year,
        grant_id: grant_ids.join(', '),
        coc_program_component: coc_program_components.join(', '),
        target_population: target_populations.join(', '),
      })
    end

    def enrollment_data_for_project(project)
      data = service_history_enrollment_scope.
          open_between(start_date: self.start, end_date: self.end).
          in_project(project).
          joins(:project, :client, :enrollment).
          pluck(*enrollment_columns.values)
      data.map do |row|
        Hash[enrollment_columns.keys.zip(row)]
      end
    end

    def add_enrollments_with_no_service
      empty_enrollments = {}
      projects.each do |project|
        if project.TrackingMethod == 3
          enrollments_in_project = enrollment_data_for_project(project)
          enrollments_with_service = service_history_enrollment_scope.
              service_within_date_range(start_date: self.start, end_date: self.end).
              in_project(project).
              distinct.
              joins(:project, :client, :enrollment).
              pluck(*enrollment_columns.values).
              map do |row|
                Hash[enrollment_columns.keys.zip(row)]
              end
          empty_enrollments[project.id] = enrollments_in_project - enrollments_with_service
        else
          empty_enrollments[project.id] = []
        end
      end
      answers = {
        enrollments_with_no_service: {}
      }
      # This only gets support as a batch
      support = {
        'enrollments_with_no_service' => {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date'],
          counts: []
        }
      }
      empty_enrollments.each do |project_id, ens|
        # NOTE: we are counting enrollments not distinct clients
        answers[:enrollments_with_no_service][project_id] = ens.count
        support['enrollments_with_no_service'][:counts] +=  ens.flatten(1).
          index_by{|m| [m[:personal_id],m[:data_source_id]]}.
          map do |_, enrollment|
            client_id = destination_id_for_client(enrollment[:id])
            [
              client_id,
              enrollment[:first_name],
              enrollment[:last_name],
              enrollment[:project_name],
              enrollment[:first_date_in_program],
              enrollment[:last_date_in_program],
            ]
          end
      end
      add_answers(answers, support)
    end

    def add_individuals_at_family_projects
      individuals = {}
      projects.each do |project|
        if project.serves_families?
          enrollments_in_project = enrollment_data_for_project(project)
          if enrollments_in_project.present? && enrollments_in_project.any?
            family_enrollments = enrollments_in_project.
              group_by do |m|
                [m[:data_source_id], m[:household_id]]
              end.select do |(_, hh_id), m|
                hh_id.nil? || m.size == 1
              end
            individuals[project.id] = family_enrollments.values.flatten(1)
          else
            individuals[project.id] = []
          end
        else
          individuals[project.id] = []
        end
      end
      answers = {
        individuals_at_family_projects: {}
      }
      support = {}
      all_clients = []
      individuals.each do |project_id, clients|
        counts = clients.map do |service|
          [
              service[:id],
              service[:first_name],
              service[:last_name],
              service[:project_name],
              service[:first_date_in_program],
              service[:last_date_in_program],
          ]
        end
        all_clients = all_clients + counts
        answers[:individuals_at_family_projects][project_id] = clients.count
        support["individuals_at_family_projects_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date'],
          counts: counts
        }
      end
      support['individuals_at_family_projects'] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: all_clients.uniq
      }
      add_answers(answers, support)
    end

    def add_families_at_individual_projects
      families = {}
      projects.each do |project|
        if project.serves_only_individuals?
          enrollments_in_project = enrollment_data_for_project(project)
          if enrollments_in_project.present? && enrollments_in_project.any?
            family_enrollments = enrollments_in_project.
              group_by do |m|
                [m[:data_source_id], m[:household_id]]
              end.select do |(_, hh_id), m|
                unique_clients = m.map do |enrollment|
                  enrollment[:id]
                end.uniq
                hh_id.present? && unique_clients.size > 1
              end
            families[project.id] = family_enrollments.values.flatten(1)
          else
            families[project.id] = []
          end
        else
          families[project.id] = []
        end
      end
      answers = {
        families_at_individual_projects: {}
      }
      support = {}
      families.each do |project_id, clients|
        # Count of families, not clients
        answers[:families_at_individual_projects][project_id] = clients.map do |client|
          client[:household_id]
        end.uniq.count
        support["families_at_individual_projects_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Household ID','Project', 'Entry Date', 'Exit Date'],
          counts: clients.map do |service|
            [
              service[:id],
              service[:first_name],
              service[:last_name],
              service[:household_id],
              service[:project_name],
              service[:first_date_in_program],
              service[:last_date_in_program],
            ]
          end
        }
      end
      add_answers(answers, support)
    end

    def add_service_after_close
      service_after_close = {}
      projects.each do |project|
        service_after_close[project.id] = []
        client_scope.entry.night_by_night.
          where(Project: {id: project.id}).
          where.not(last_date_in_program: nil).
          pluck(*service_columns.values).
        map do |row|
          Hash[service_columns.keys.zip(row)]
        end.each do |row|
          last_date = client_scope.entry.night_by_night.
            where(
              enrollment_group_id: row[:enrollment_group_id],
              first_date_in_program: row[:first_date_in_program]
            ).joins(enrollment: :services).maximum('"DateProvided"')
          if last_date.present? && last_date > row[:last_date_in_program]
            row[:late_service] = last_date
            service_after_close[project.id] << row
          end
        end
      end
      answers = {
        service_after_close: service_after_close.map do |project_id, clients|
          [project_id, clients.count]
        end.to_h
      }
      support = {}
      all_clients = []
      service_after_close.each do |project_id, clients|
        counts = clients.map do |service|
          client_id = destination_id_for_client(service[:id])
          [
              client_id,
              service[:first_name],
              service[:last_name],
              service[:project_name],
              service[:first_date_in_program],
              service[:last_date_in_program],
              service[:late_service],
          ]
        end
        all_clients = all_clients + counts
        support["service_after_close_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: counts
        }
      end
      support['service_after_close'] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: all_clients.uniq
      }
      add_answers(answers, support)
    end

    def add_night_by_night_missing
      missing_nights = {}
      projects.each do |project|
        missing_nights[project.id] = []
        client_scope.night_by_night.entry.where(Project: {id: project.id}).
          pluck(*service_columns.values).
        map do |row|
          Hash[service_columns.keys.zip(row)]
        end.each do |row|
          # set the range to the last 30 days of the enrollment or reporting period
          # if the enrollment is still open
          end_date = self.end
          if row[:last_date_in_program].present? && row[:last_date_in_program] < self.end
            end_date = row[:last_date_in_program]
          end
          thirty_days_before_end = end_date - 30.days
          max_date = client_scope.joins(:service_history_services).where(
            client_id: row[:client_id],
            first_date_in_program: row[:first_date_in_program],
            enrollment_group_id: row[:enrollment_group_id]
          ).pluck(shs_t[:date].maximum.to_sql)&.first
          if max_date.present? && max_date < thirty_days_before_end.to_date
            row[:max_date] = max_date
            missing_nights[project.id] << row
          end
        end
      end
      answers = {
        missing_nights: missing_nights.map do |project_id, clients|
          [project_id, clients.count]
        end.to_h
      }
      support = {}
      all_clients = []
      missing_nights.each do |project_id, clients|
        counts = clients.map do |service|
          client_id = destination_id_for_client(service[:id])
          [
              client_id,
              service[:first_name],
              service[:last_name],
              service[:project_name],
              service[:first_date_in_program],
              service[:last_date_in_program],
              service[:max_date],
          ]
        end
        all_clients = all_clients + counts
        support["missing_nights_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: counts
        }
      end
      support['missing_nights'] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: all_clients.uniq
      }
      add_answers(answers, support)
    end

    def add_clients_dob_enrollment_date
      dob_entry = {}
      projects.each do |project|
        dob_entry[project.id] ||= Set.new
        enrollments_in_project = enrollment_data_for_project(project)
        if enrollments_in_project.present? && enrollments_in_project.any?
          enrollments_in_project.each do |enrollment|
            if enrollment[:dob].present? && enrollment[:dob].to_date >= enrollment[:first_date_in_program].to_date
              dob_entry[project.id] << [
                enrollment[:id],
                enrollment[:first_name],
                enrollment[:last_name],
                enrollment[:dob],
                enrollment[:first_date_in_program],
                enrollment[:project_name],
              ]
            end
          end
        end
      end
      support = {}
      all_clients = []
      dob_entry.each do |project_id, clients|
        support["incorrect_dob_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'Entry Date', 'Project'],
          counts: clients.to_a
        }
        all_clients = all_clients + clients.to_a
      end
      support["incorrect_dob"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'Entry Date', 'Project'],
          counts: all_clients.uniq
      }
      answers = {incorrect_dob: dob_entry.map{|project_id, clients| [project_id, clients.count]}.to_h}
      add_answers(answers, support)
    end

    def add_enrolled_length_of_stay
      project_counts = projects.map do |project|
        [
          project.id,
          {
            average: 0,
            buckets: {}
          }
        ]
      end.to_h
      project_support = projects.map do |project|
        [
            project.id,
            {
                buckets: {}
            }
        ]
      end.to_h
      totals = {
        buckets: self.class.length_of_stay_buckets.map do |title, range|
          [range, Set.new]
        end.to_h,
        counts: {
          total_days: 0,
          total_clients: 0,
        },
      }

      total_client_set = Set.new

      projects.each do |project|
        counts = self.class.length_of_stay_buckets.map do |title, range|
          [range, Set.new]
        end.to_h
        service_histories = service_scope.
          where(Project: {id: project.id}).
          order(shs_t[:date].asc).
          pluck(*service_columns.values, shs_t[:date].as('date').to_sql).
          map do |row|
            Hash[(service_columns.keys + [:date]).zip(row)]
          end.uniq
        service_history_count = service_histories.select{|m| m[:date].present?}.count
        totals[:counts][:total_days] += service_histories.count
        total_client_set += service_histories.map{|m| m[:client_id]}
        service_histories = service_histories.group_by{|m| m[:id]}
        # days/client
        project_counts[project.id][:average] = (service_history_count.to_f / service_histories.count).round rescue 0
        service_histories.each do |client_id, services|
          counts.each do |range, _|
            meta = services.first
            meta[:service_count] = services.select{|m| m[:date].present?}.count
            if range.include?(meta[:service_count])
              counts[range] << meta
              totals[:buckets][range] << meta
            end
          end
        end
        project_counts[project.id][:buckets] = counts.map{|range,services| [range, services.count]}.to_h
        project_support[project.id][:buckets] = counts
      end

      # count the total number of clients
      totals[:counts][:total_clients] = total_client_set.size

      # average length of stay, days / people
      totals[:counts][:average] = (totals[:counts][:total_days].to_f / totals[:counts][:total_clients]).round rescue 0
      totals[:counts][:buckets] = totals[:buckets].map{|range,services| [range,services.count]}.to_h

      json_shape = {
        labels: self.class.length_of_stay_buckets.keys,
        data: begin
          data_map = {}
          projects.each do |project|
            name = project.ProjectName
            data_map[name] = []
            self.class.length_of_stay_buckets.values.each do |range|
              data_map[name] << project_counts[project.id][:buckets][range] rescue 0
            end
          end
          data_map['Total'] = []
          self.class.length_of_stay_buckets.values.each do |range|
            data_map['Total'] << totals[:counts][:buckets][range] if projects.count > 1
          end
          data_map
        end,
        ranges: self.class.length_of_stay_buckets,
        projects: projects.map{|m| [m.name, m.id]}.to_h,
      }

      answers = {
        enrolled_length_of_stay: json_shape,
        length_of_stay_totals: totals[:counts],
      }
      support = {}
      project_support.each do |project_id, buckets|
        buckets[:buckets].each do |range, services|
          support["enrolled_length_of_stay_#{project_id}_#{range}"] = {
            headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Days Served'],
            counts: services.map do |service|
              [
                destination_id_for_client(service[:id]),
                service[:first_name],
                service[:last_name],
                service[:project_name],
                service[:first_date_in_program],
                service[:last_date_in_program],
                service[:service_count]
              ]
            end
          }
        end
      end
      totals[:buckets].each do |range, services|
        support["enrolled_length_of_stay_totals_#{range}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date'],
          counts: services.map do |service|
            [
              destination_id_for_client(service[:id]),
              service[:first_name],
              service[:last_name],
              service[:project_name],
              service[:first_date_in_program],
              service[:last_date_in_program],
            ]
          end
        }
      end
      add_answers(answers, support)
    end

    def add_missing_values
      totals = {}
      answers = {project_missing: {}}
      support = {}
      self.class.missing_refused_names.keys.each do |word|
        totals["missing_#{word}"] = Set.new
        totals["refused_#{word}"] = Set.new
        totals["unknown_#{word}"] = Set.new
      end
      totals["no_interview_destination"] = Set.new

      projects.each do |project|
        counts = {}
        # Reset for each project
        # @refused_ssn_client_ids = Set.new
        # @refused_dob_client_ids = Set.new
        self.class.missing_refused_names.keys.each do |word|
          counts["missing_#{word}"] = Set.new
          counts["refused_#{word}"] = Set.new
          counts["unknown_#{word}"] = Set.new
        end
        counts["no_interview_destination"] = Set.new

        clients_in_project = clients_for_project(project.id)
        clients_in_project.each do |client|
          # NOTE: Unknown and refused must come before missing or we get duplicates
          counts = add_refused_demo(client: client, counts: counts)
          counts = add_unknown_demo(client: client, counts: counts)
          counts = add_missing_demo(client: client, counts: counts)
        end
        enrollments_in_project = enrollments_for_project(project.ProjectID, project.data_source_id)
        if enrollments_in_project.present? && enrollments_in_project.any?
          enrollments_in_project.each do |client_id, enrollments|
            if enrollments.present?
              enrollments.each do |enrollment|
                counts = add_missing_enrollment(client_id: client_id, enrollment: enrollment, counts: counts)
                counts = add_refused_enrollment(client_id: client_id, enrollment: enrollment, counts: counts)
                counts = add_unknown_enrollment(client_id: client_id, enrollment: enrollment, counts: counts)
                counts = add_missing_entry_incomes(client_id: client_id, enrollment: enrollment, counts: counts)
              end
            end
            leavers_in_project = leavers_for_project(project.ProjectID, project.data_source_id)
            if leavers_in_project.present? && leavers_in_project.any?
              leavers_in_project.each do |client_id|
                enrollments_in_project[client_id].each do |enrollment|
                  counts = add_missing_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                  counts = add_refused_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                  counts = add_unknown_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                  counts = add_no_interview_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                  counts = add_missing_exit_incomes(client_id: client_id, enrollment: enrollment, counts: counts)
                end
              end
            end
          end
        end

        counts.each do |key, value|
          totals[key] += value
          answers[:project_missing][project.id] ||= {}
          item_count = value.size
          # disabling conditions can occur more than once per enrollment, count unique clients
          if key.to_s.include?('disabling_condition')
            item_count = value&.map(&:first)&.uniq&.count || 0
          end
          answers[:project_missing][project.id][key] = item_count
          answers[:project_missing][project.id]["#{key}_percentage"] = in_percentage(item_count, clients_in_project.size)
          header_key = key.to_s.gsub('missing_', '').gsub('refused_', '').gsub('unknown_', '').to_sym
          support["project_missing_#{project.id}_#{key}"] = {
            headers: self.class.missing_refused_names[header_key],
            counts: value.to_a.map do |row|
              # use the destination id for the client for support
              row[0] = destination_id_for_client(row.first)
              row
            end
          }
        end
        answers[:project_missing][project.id][:total_open_enrollments] = clients_in_project.size
        answers[:project_missing][project.id][:clients_served_during_range] = service_scope.
          where(Project: {id: project.id}).
          service_within_date_range(start_date: self.start, end_date: self.end).
          select(:client_id).
          distinct.
          count
        incorrect_clients = counts.values.reduce(&:+).map(&:first).to_set
        missing_clients = counts.select{|k,_| k.include?('missing')}.values.reduce(&:+).map(&:first).to_set
        refused_clients = counts.select{|k,_| k.include?('refused')}.values.reduce(&:+).map(&:first).to_set
        does_not_know_clients = counts.select{|k,_| k.include?('unknown')}.values.reduce(&:+).map(&:first).to_set

        totals[:total_missing] ||= Set.new
        totals[:total_missing] += missing_clients
        answers[:project_missing][project.id][:total_missing] = missing_clients.size
        answers[:project_missing][project.id][:total_missing_percentage] = in_percentage(missing_clients.size, clients_in_project.size)
        answers[:project_missing][project.id][:total_refused] = refused_clients.size
        answers[:project_missing][project.id][:total_refused_percentage] = in_percentage(refused_clients.size, clients_in_project.size)
        answers[:project_missing][project.id][:total_unknown] = does_not_know_clients.size
        answers[:project_missing][project.id][:total_unknown_percentage] = in_percentage(does_not_know_clients.size, clients_in_project.size)
        answers[:project_missing][project.id][:total_incorrect] = incorrect_clients.size
        answers[:project_missing][project.id][:total_incorrect_percentage] = in_percentage(incorrect_clients.size, clients_in_project.size)
        answers[:project_missing][project.id][:score] = in_percentage(incorrect_clients.size, clients_in_project.size)
      end
      answers[:project_missing][:totals] = totals.map do |key, clients|
        [key, clients.count]
      end.to_h
      answers[:project_missing][:totals][:score] = in_percentage(totals.values.map(&:size).max, clients.size)
      totals[:total_open_enrollments] = clients
      answers[:project_missing][:totals][:total_open_enrollments] = totals[:total_open_enrollments].size
      answers[:project_missing][:totals][:clients_served_during_range] = service_scope.
        service_within_date_range(start_date: self.start, end_date: self.end).
        select(:client_id).
        distinct.
        count
      totals.each do |key, value|
        header_key = key.to_s.gsub('missing_', '').gsub('refused_', '').gsub('unknown_', '').to_sym
        item_count = value.count
        # disabling conditions may get reported multiple times per enrollment, we want unique client counts
        if header_key == :disabling_condition
          item_count = value&.map(&:first)&.uniq&.count || 0
        end
        answers[:project_missing][:totals]["#{key}_percentage"] = in_percentage(item_count, clients.size)
        if ! [:total_open_enrollments, :total_missing, :clients_served_during_range].include?(key)
          support["project_missing_totals_#{key}"] = {
            headers: self.class.missing_refused_names[header_key],
            counts: value.to_a
          }
        end
      end

      json_shape = {}
      all_completeness_percentages = []
      projects.each do |project|
        name = project.ProjectName
        data = answers[:project_missing][project.id]
        all_completeness_percentages += completeness_percentages(data)
        json_shape[name] = {
          labels: self.class.completeness_field_names.values,
          data: {
            "Complete": completeness_percentages(data),
            # "Anonymous": Array.new(self.class.completeness_field_names.values.size, 0),
            "No Exit Interview Completed": no_interview_percentages(data),
            "Don't Know / Refused": missing_or_dont_know_percentages(data),
            "Missing / Null": incompleteness_percentages('missing', data),
            'Target': Array.new(self.class.completeness_field_names.values.size, completeness_goal),
          }
        }
      end

      completeness_percentage = all_completeness_percentages.sum / all_completeness_percentages.size
      answers = { project_missing: json_shape, completeness_percentage: completeness_percentage }

      add_answers(answers, support)
    end

    def self.completeness_field_names
      {
        #first_name: "First Name",
        #last_name: "Last Name",
        name: "Name",
        dob: "DOB",
        ssn: "SSN",
        race: "Race",
        ethnicity: "Ethnicity",
        gender: "Gender",
        veteran: "Veteran Status",
        disabling_condition: "Disabling Condition",
        prior_living_situation: "Living Situation",
        income_at_entry: "Income At Entry",
        income_at_exit: "Income At Exit",
        destination: "Destination",
      }
    end

    def completeness_percentages(data)
      result = Vector::elements(Array.new(self.class.completeness_field_names.values.size, 100))
      result -= Vector::elements(incompleteness_percentages('missing', data))
      result -= Vector::elements(incompleteness_percentages('refused', data))
      result -= Vector::elements(incompleteness_percentages('unknown', data))
      result -= Vector::elements(no_interview_percentages(data))
      return result.to_a
    end

    def missing_or_dont_know_percentages(data)
      result = Vector::elements(incompleteness_percentages('refused', data))
      result += Vector::elements(incompleteness_percentages('unknown', data))
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
          result << data["no_interview_destination_percentage"].round
        else
          result << 0
        end
      end
      return result
    end

    def add_households
      answers = { households: {} }
      support = {}
      total_enrolled_households = 0
      all_enrolled_households = Set.new
      total_active_households = 0
      all_active_households = Set.new

      projects.each do |project|
        enrolled_households = service_history_enrollment_scope.
            open_between(start_date: self.start, end_date: self.end).
            joins(:project).
            where(Project: {id: project.id}).
            group(:household_id).
            distinct.
            pluck(:household_id)
        all_enrolled_households.merge(enrolled_households)
        active_households = service_history_enrollment_scope.
            service_within_date_range(start_date: self.start, end_date: self.end).
            joins(:project).
            where(Project: {id: project.id}).
            group(:household_id).
            distinct.
            pluck(:household_id)
        all_active_households.merge(active_households)

        answers[:households][project.id] ||= {}

        answers[:households][project.id][:enrolled_households] = enrolled_households.size
        total_enrolled_households += enrolled_households.size
        support["enrolled_households_#{project.id}"] = household_support(enrolled_households)

        answers[:households][project.id][:active_households] = active_households.size
        total_active_households += active_households.size
        support["active_households_#{project.id}"] = household_support(active_households)
      end
      answers[:households][:total_enrolled_households] = total_enrolled_households
      answers[:households][:total_active_households] = total_active_households

      support[:total_active_households] = household_support(all_active_households.to_a)
      support[:total_households] = household_support(all_enrolled_households.to_a)

      support[:total_entering_households] = transitioning_household_support(entering_households)
      support[:total_exiting_households] = transitioning_household_support(exiting_households)
      add_answers(answers, support)
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

      enrollment_ids = hohs.map{|m| m[:enrollment_id]}
      # min_enrollment_date = hohs.map{|c| c[:first_date_in_program]}.min
      max_exit_date = (hohs.map{|c| c[:last_date_in_program]}.compact + [Date.current]).max
      max_dates = max_dates_served(enrollment_ids, range: (self.start..max_exit_date))

      hohs.each do |hoh|
        dest = hoh[:destination].to_i
        if dest != 0
          hoh[:destination_text] = "#{dest}: #{HUD.destination(dest)}"
        end

        hoh[:most_recent_service] = max_dates[hoh[:enrollment_id]] || 'Before report start'
        hoh.delete(:enrollment_id)
      end
      {
        headers: ['Client ID', 'First Name', 'Last Name', "First Date In Program", "Last Date In Program", "Most Recent Service", "Destination"],
        counts: hohs.map do |hoh|
          [ hoh[:client_id], hoh[:first_name], hoh[:last_name], hoh[:first_date_in_program],
            hoh[:last_date_in_program], hoh[:most_recent_service], hoh[:destination_text] ]
        end,
      }
    end

    def transitioning_household_support(households)
      hohs = households.values.deep_dup.map(&:first)

      enrollment_ids = hohs.map{|m| m[:enrollment_id]}
      # min_enrollment_date = hohs.map{|c| c[:first_date_in_program]}.min
      max_exit_date = (hohs.map{|c| c[:last_date_in_program]}.compact + [Date.current]).max
      max_dates = max_dates_served(enrollment_ids, range: (self.start..max_exit_date))

      hohs.each do |hoh|
        dest = hoh[:destination].to_i
        if dest != 0
          hoh[:destination_text] = "#{dest}: #{HUD.destination(dest)}"
        end
        hoh[:most_recent_service] = max_dates[hoh[:enrollment_id]] || 'Before report start'
        hoh.delete(:enrollment_id)
      end
      {
          headers: ['Client ID', 'First Name', 'Last Name', "First Date In Program", "Last Date In Program", "Most Recent Service", "Destination"],
          counts: hohs.map do |hoh|
            [ hoh[:id], hoh[:first_name], hoh[:last_name], hoh[:first_date_in_program],
                hoh[:last_date_in_program], hoh[:most_recent_service], hoh[:destination_text] ]
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

    def base_colums_for_support enrollment
      [
        enrollment[:id],
        enrollment[:first_name],
        enrollment[:last_name],
      ]
    end

    def columns_for_income_at_entry enrollment
      base_colums_for_support(entrollment)
    end

    def columns_for_income_at_exit enrollment
      base_colums_for_support(entrollment)
    end

    def columns_for_missing_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:name_data_quality],
        enrollment[:ssn],
        enrollment[:ssn_data_quality],
        enrollment[:dob],
        enrollment[:dob_data_quality],
      ]
    end

    def columns_for_destination_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:destination]
      ]
    end

    # this may return multiple rows per client and must be added to the support
    # stack with += instead of <<
    def columns_for_disabling_condition_support enrollment, disabilities, value
      if disabilities.blank?
        [base_colums_for_support(enrollment) + [
          nil,
          nil,
        ]]
      else
        disabilities.select do |dis|
          dis[:disability_response].to_i == value
        end.map do |dis|
          base_colums_for_support(enrollment) + [
          HUD.disability_type(dis[:disability_type]),
          dis[:disability_response],
        ]
        end
      end
    end

    def columns_for_gender_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:gender]
      ]
    end

    def columns_for_veteran_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:veteran_status]
      ]
    end

    def columns_for_first_name_support enrollment
      base_colums_for_support(enrollment) + [
          99 # Data Quality Code "Data Not Collected", There is no DQ for first name, field added to keep shape consistent
      ]
    end

    def columns_for_last_name_support enrollment
      base_colums_for_support(enrollment) + [
          99 # Data Quality Code "Data Not Collected", There is no DQ for last name, field added to keep shape consistent
      ]
    end

    def columns_for_name_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:name_data_quality]
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
        enrollment[:ethnicity]
      ]
    end

    def columns_for_residence_prior_support enrollment
      base_colums_for_support(enrollment) + [
        enrollment[:residence_prior]
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


    def add_missing_destinations client_id:, enrollment:, counts:
      if missing?(enrollment[:destination])
        counts['missing_destination'] << columns_for_destination_support(enrollment)
      end
      return counts
    end

    def add_refused_destinations client_id:, enrollment:, counts:
      if refused?(enrollment[:destination])
        counts['refused_destination'] << columns_for_destination_support(enrollment)
      end
      return counts
    end

    def add_unknown_destinations client_id:, enrollment:, counts:
      if unknown?(enrollment[:destination])
        counts['unknown_destination'] << columns_for_destination_support(enrollment)
      end
      return counts
    end

    def add_no_interview_destinations client_id:, enrollment:, counts:
      if no_exit_interview?(enrollment[:destination])
        counts['no_interview_destination'] << columns_for_destination_support(enrollment)
      end
      return counts
    end

    def no_exit_interview?(value)
      value.to_i == 30
    end


    def add_missing_enrollment client_id:, enrollment:, counts:
      disabilities = disabilities_for_enrollment(enrollment)
      if missing_disability?(disabilities)
        counts['missing_disabling_condition'] += columns_for_disabling_condition_support(enrollment, disabilities, 99)
      end
      if missing?(enrollment[:residence_prior]) && adult?(enrollment[:age])  && enrollment[:head_of_household]
        counts['missing_prior_living_situation'] << columns_for_residence_prior_support(enrollment)
      end
      # if missing?(enrollment[:last_permanent_zip])
      #   counts['missing_last_permanent_zip'] << columns_for_last_permanent_zip_support(enrollment)
      # end
      return counts
    end

    def add_refused_enrollment client_id:, enrollment:, counts:
      disabilities = disabilities_for_enrollment(enrollment)
      if refused_diability?(disabilities)
        counts['refused_disabling_condition'] += columns_for_disabling_condition_support(enrollment, disabilities, 9)
      end
      if refused?(enrollment[:residence_prior]) && adult?(enrollment[:age]) && enrollment[:head_of_household]
        counts['refused_prior_living_situation'] << columns_for_residence_prior_support(enrollment)
      end
      # if refused?(enrollment[:last_permanent_zip])
      #   counts['refused_last_permanent_zip'] << columns_for_last_permanent_zip_support(enrollment)
      # end
      return counts
    end

    def add_unknown_enrollment client_id:, enrollment:, counts:
      disabilities = disabilities_for_enrollment(enrollment)
      if unknown_disability?(disabilities)
        counts['unknown_disabling_condition'] += columns_for_disabling_condition_support(enrollment, disabilities, 8)
      end
      if unknown?(enrollment[:residence_prior]) && adult?(enrollment[:age]) && enrollment[:head_of_household]
        counts['unknown_prior_living_situation'] << columns_for_residence_prior_support(enrollment)
      end
      # if unknown?(enrollment[:last_permanent_zip])
      #   counts['unknown_last_permanent_zip'] << columns_for_last_permanent_zip_support(enrollment)
      # end
      return counts
    end

    def add_missing_demo client:, counts:
      alternate_clients = source_clients_for_source_client(source_client_id: client[:destination_id], data_source_id: client[:data_source_id])
      alternate_all_adults = alternate_clients.map{|m| adult?(age(m[:dob]))}.all?
      if alternate_clients.map{|m| m[:first_name]}.all?(&:blank?)
        counts['missing_first_name'] << columns_for_first_name_support(client)
      end
      if alternate_clients.map{|m| m[:last_name]}.all?(&:blank?)
        counts['missing_first_name'] << columns_for_last_name_support(client)
      end
      if alternate_clients.map{|m| m[:first_name]}.all?(&:blank?) || alternate_clients.map{|m| m[:last_name]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:name_data_quality])}.all?
        counts['missing_name'] << columns_for_name_support(client)
      end
      # Refused trumps missing
      if alternate_clients.map{|m| m[:ssn]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:ssn_data_quality])}.all?
        counts['missing_ssn'] << columns_for_ssn_support(client) unless @refused_ssn_client_ids.include?(client[:destination_id])
      end
      if alternate_clients.map{|m| m[:dob]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:dob_data_quality])}.all?
        counts['missing_dob'] << columns_for_dob_support(client) unless @refused_dob_client_ids.include?(client[:destination_id])
      end
      if alternate_all_adults && (alternate_clients.map{|m| m[:veteran_status]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:veteran_status])}.all?)
        counts['missing_veteran'] << columns_for_veteran_support(client)
      end
      if alternate_clients.map{|m| m[:ethnicity]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:ethnicity])}.all?
        counts['missing_ethnicity'] << columns_for_ethnicity_support(client)
      end
      # If we have no race info, whatsoever
      if alternate_clients.map{|m| missing?(m[:race_none])}.all? && alternate_clients.map{|m| missing?(m[:am_ind_ak_native])}.all? &&
        alternate_clients.map{|m| missing?(m[:asian])}.all? && alternate_clients.map{|m| missing?(m[:black_af_american])}.all? &&
        alternate_clients.map{|m| missing?(m[:native_hi_other_pacific])}.all? && alternate_clients.map{|m| missing?(m[:white])}.all?
        counts['missing_race'] << columns_for_race_support(client)
      end
      if alternate_clients.map{|m| m[:gender]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:gender])}.all?
        counts['missing_gender'] << columns_for_gender_support(client)
      end
      return counts
    end

    def add_refused_demo client:, counts:
      alternate_clients = source_clients_for_source_client(source_client_id: client[:destination_id], data_source_id: client[:data_source_id])
      alternate_all_adults = alternate_clients.map{|m| adult?(age(m[:dob]))}.all?
      if alternate_clients.map{|m| refused?(m[:name_data_quality])}.all?
        counts['refused_name'] << columns_for_name_support(client)
      end
      # Refused trumps missing
      if alternate_clients.map{|m| refused?(m[:ssn_data_quality])}.all?
        @refused_ssn_client_ids << client[:destination_id]
        counts['refused_ssn'] << columns_for_ssn_support(client)
      end
      if alternate_clients.map{|m| refused?(m[:dob_data_quality])}.all?
        @refused_dob_client_ids << client[:destination_id]
        counts['refused_dob'] << columns_for_dob_support(client)
      end
      if alternate_all_adults && alternate_clients.map{|m| refused?(m[:veteran_status])}.all?
        counts['refused_veteran'] << columns_for_veteran_support(client)
      end
      if alternate_clients.map{|m| refused?(m[:ethnicity])}.all?
        counts['refused_ethnicity'] << columns_for_ethnicity_support(client)
      end
      if alternate_clients.map{|m| refused?(m[:race_none])}.all?
        counts['refused_race'] << columns_for_race_support(client)
      end
      if alternate_clients.map{|m| refused?(m[:gender])}.all?
        counts['refused_gender'] << columns_for_gender_support(client)
      end
      return counts
    end

    def add_unknown_demo client:, counts:
      alternate_clients = source_clients_for_source_client(source_client_id: client[:destination_id], data_source_id: client[:data_source_id])
      alternate_all_adults = alternate_clients.map{|m| adult?(age(m[:dob]))}.all?
      if alternate_clients.map{|m| unknown?(m[:name_data_quality])}.all?
        counts['unknown_name'] << columns_for_name_support(client)
      end
      if alternate_clients.map{|m| unknown?(m[:ssn_data_quality])}.all?
        @refused_ssn_client_ids << client[:destination_id]
        counts['unknown_ssn'] << columns_for_ssn_support(client)
      end
      if alternate_clients.map{|m| unknown?(m[:dob_data_quality])}.all?
        @refused_dob_client_ids << client[:destination_id]
        counts['unknown_dob'] << columns_for_dob_support(client)
      end
      if alternate_all_adults && alternate_clients.map{|m| unknown?(m[:veteran_status])}.all?
        counts['unknown_veteran'] << columns_for_missing_support(client)
      end
      if alternate_clients.map{|m| unknown?(m[:ethnicity])}.all?
        counts['unknown_ethnicity'] << columns_for_ethnicity_support(client)
      end
      if alternate_clients.map{|m| unknown?(m[:race_none])}.all?
        counts['unknown_race'] << columns_for_race_support(client)
      end
      if alternate_clients.map{|m| unknown?(m[:gender])}.all?
        counts['unknown_gender'] << columns_for_gender_support(client)
      end
      return counts
    end

    def add_missing_entry_incomes client_id:, enrollment:, counts:
      if missing_income(client_id, enrollment, data_collection_stage: 1)
        counts['missing_income_at_entry'] << columns_for_destination_support(enrollment)
      end

      return counts
    end

    def add_missing_exit_incomes client_id:, enrollment:, counts:
      if missing_income(client_id, enrollment, data_collection_stage: 3)
        counts['missing_income_at_exit'] << columns_for_destination_support(enrollment)
      end

      return counts
    end

    def add_bed_utilization
      bed_utilization = []
      support = {}
      totals = {counts: Hash.new(0), data: Hash.new(Set.new)}

      projects.each do |project|
        counts = {}
        data = {}

        counts[:capacity] = project.inventories.within_range(filter.range).map{|i| i[:BedInventory] || 0}.sum
        total_count = project.service_history_enrollments.
          service_within_date_range(start_date: self.start, end_date: self.end).
          count

        utilization = project.service_history_enrollments.
          service_within_date_range(start_date: self.start, end_date: self.end).
          joins(:client).
          distinct.
          pluck(*bed_utilization_client_columns.values).map do |row|
          Hash[bed_utilization_client_columns.keys.zip(row)]
        end.group_by do |row|
          row[:date]
        end

        data[:average_daily] = utilization.values.flatten.map(&:values)
        counts[:average_daily] = total_count / filter.range.count rescue 0

        filter.range.each do |date|
          key = date.to_formatted_s(:iso8601)
          data[key] = utilization[date]&.map(&:values) || []
          counts[key] = data[key].count
        end

        project_counts = {
          id: project.id,
          name: project.ProjectName,
          project_type: project[GrdaWarehouse::Hud::Project.project_type_column],
        }.merge(counts)

        totals[:counts][:capacity] += counts[:capacity]
        self.class.bed_utilization_attributes.each do |attr|
          project_counts["#{attr}_percentage"] = in_percentage(counts[attr], counts[:capacity])
          totals[:counts][attr] += counts[attr]
          # totals[:data][attr] += data[attr]
          support["bed_utilization_#{project.id}_#{attr}"] = {
            headers: ['Client ID', 'First Name', 'Last Name'],
            counts: data[attr]
          }
        end
        counts.select do |key, value|
          if key.to_s.match(/\d{4}-\d{2}-\d{2}/)
            totals[:counts][key] += value
          end
        end

        bed_utilization << project_counts
      end

      self.class.bed_utilization_attributes.each do |attr|
        totals[:counts]["#{attr}_percentage"] = in_percentage(totals[:counts][attr], totals[:counts][:capacity])
        support["bed_utilization_totals_#{attr}"] = {
          headers: ['Client ID', 'First Name', 'Last Name'],
          counts: totals[:data][attr]
        }
      end

      json_shape = {
        labels: bed_utilization.first.select do |key, _|
          key.to_s.match(/\d{4}-\d{2}-\d{2}/)
        end.keys.map do |k|
          k&.to_date&.strftime('%D')
        end,
        data: begin
          data_map = {}
          bed_utilization.each do |project|
            project_name = project[:name]
            data_map[project_name] = project.select do |key, _|
              key.to_s.match(/\d{4}-\d{2}-\d{2}/)
            end.values
          end
          if data_map.size > 1
            data_map['Total'] = totals[:counts].select do |key, _|
              key.to_s.match(/\d{4}-\d{2}-\d{2}/)
            end.values
          end
          data_map
        end
      }

      add_answers(
        {
          bed_utilization: json_shape,
          bed_utilization_totals: totals,
        },
        support
      )

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

    def set_bed_coverage_data
      bed_coverage = 0
      bed_coverage_percent = 0
      if hmis_beds > 0
        bed_coverage = "#{beds} / #{hmis_beds}" rescue 0
        bed_coverage_percent = (beds.to_f/hmis_beds*100).round(2) || 0
      end
      add_answers({
        bed_coverage: bed_coverage,
        bed_coverage_percent: bed_coverage_percent,
      })
    end

    def add_unit_utilization
      unit_utilization = []
      support = {}
      totals = {counts: Hash.new(0), data: Hash.new(Set.new)}

      projects.each do |project|
        counts = {}
        data = {}

        counts[:capacity] = project.inventories.within_range(filter.range).map{|i| i[:UnitInventory] || 0}.sum

        utilization = project.service_history_enrollments.
          joins(:client, :enrollment).
          service_within_date_range(start_date: self.start, end_date: self.end).
          merge(GrdaWarehouse::Hud::Enrollment.heads_of_households).
          distinct.
          pluck(*unit_utilization_client_columns.values).map do |row|
          Hash[unit_utilization_client_columns.keys.zip(row)]
        end.group_by do |row|
          row[:date]
        end
        data[:average_daily] = utilization.values.flatten.map(&:values)

        daily_household = project.service_history_enrollments.
          service_within_date_range(start_date: self.start, end_date: self.end).
          joins(:client).
          distinct.
          group(shs_t[:date]).
          count(she_t[:household_id].to_sql)

        counts[:average_daily] = daily_household.values.sum.to_f / filter.range.count rescue 0

        filter.range.each do |date|
          key = date.to_formatted_s(:iso8601)
          data[key] = utilization[date]&.map(&:values) || []
          counts[key] = data[key].count
        end

        project_counts = {
          id: project.id,
          name: project.ProjectName,
          project_type: project[GrdaWarehouse::Hud::Project.project_type_column],
        }.merge(counts)

        totals[:counts][:capacity] += counts[:capacity]
        self.class.unit_utilization_attributes.each do |attr|
          percentage = in_percentage(counts[attr], counts[:capacity])
          percentage = 0 if percentage.infinite?
          totals[:counts][attr] += counts[attr]
          project_counts["#{attr}_percentage"] = percentage
          # totals[:data][attr] += data[attr]
          support["unit_utilization_#{project.id}_#{attr}"] = {
              headers: ['Client ID', 'First Name', 'Last Name'],
              counts: data[attr]
          }
        end

        unit_utilization << project_counts
      end

      self.class.unit_utilization_attributes.each do |attr|
        percentage = in_percentage(totals[:counts][attr], totals[:counts][:capacity])
        percentage = 0 if percentage.infinite?
        totals[:counts]["#{attr}_percentage"] = percentage
        support["unit_utilization_totals_#{attr}"] = {
          headers: ['Client ID', 'First Name', 'Last Name'],
          counts: totals[:data][attr]
        }
      end

      json_shape = {
          labels: unit_utilization.first.select do |key, _|
            key.to_s.match(/\d{4}-\d{2}-\d{2}/)
          end.keys.map do |k|
            k&.to_date&.strftime('%D')
          end,
          data: begin
            data_map = {}
            unit_utilization.each do |project|
              project_name = project[:name]
              data_map[project_name] = project.select do |key, _|
                key.to_s.match(/\d{4}-\d{2}-\d{2}/)
              end.values
            end
            if data_map.size > 1
              data_map['Total'] = totals[:counts].select do |key, _|
                key.to_s.match(/\d{4}-\d{2}-\d{2}/)
              end.values
            end
            data_map
          end
      }

      add_answers(
        {
          unit_utilization: json_shape,
          unit_utilization_totals: totals,
        },
        support
      )
    end

    def self.unit_utilization_attributes
      [
        :average_daily,
      ]
    end

    def add_agency_entering_data
      r = report.with_indifferent_access
      agency_name = r[:agency_name].present?
      project_name = r[:project_name].present?
      monitoring_date_range_present = r[:monitoring_date_range_present]
      grant_id = r[:grant_id].present?
      coc_program_component = r[:coc_program_component].present?
      beds_logged = r[:bed_coverage_percent] > 0 rescue false
      entering_required_data = agency_name && project_name && monitoring_date_range_present && grant_id && coc_program_component && beds_logged
      add_answers({
        entering_required_data: entering_required_data
      })
    end

    def add_data_timeliness
      entry_timeliness = {}
      entry_timeliness_support = {}
      projects.each do |project|
        entry_timeliness[project.ProjectName] = []
      end
      entry_total = 0
      entry_count = 0
      entries.each do |client_id, enrollments|
        enrollments.each do |enrollment|
          service_date = enrollment[:first_date_in_program]
          record_date = enrollment[:enrollment_created].to_date
          timeliness = (record_date - service_date).to_i
          entry_timeliness[enrollment[:project_name]] ||= []
          entry_timeliness[enrollment[:project_name]] << timeliness
          entry_total += timeliness
          entry_count += 1
          entry_timeliness_support[enrollment[:project_name]] ||= []
          entry_timeliness_support[enrollment[:project_name]] << [client_id, enrollment[:first_name], enrollment[:last_name], enrollment[:project_name], service_date, record_date]
        end
      end
      exit_timeliness = {}
      projects.each do |project|
        exit_timeliness[project.ProjectName] = []
      end
      exit_timeliness_support = {}
      exit_total = 0
      exit_count = 0
      exits.each do |client_id, enrollments|
        enrollments.each do |enrollment|
          service_date = enrollment[:last_date_in_program]
          record_date = enrollment[:exit_created].to_date
          timeliness = (record_date - service_date).to_i
          exit_timeliness[enrollment[:project_name]] ||= []
          exit_timeliness[enrollment[:project_name]] << timeliness
          exit_total += timeliness
          exit_count += 1
          exit_timeliness_support[enrollment[:project_name]] ||= []
          exit_timeliness_support[enrollment[:project_name]] << [client_id, enrollment[:first_name], enrollment[:last_name], enrollment[:project_name], service_date, record_date]
        end
      end

      json_entry_shape = {}
      entry_timeliness.keys.each do |project_name|
        json_entry_shape[project_name] = [0, (entry_timeliness[project_name].sum / entry_timeliness[project_name].size rescue 0), 0]
      end
      if entry_timeliness.keys.count > 1
        json_entry_shape['Average'] = [0, (entry_total / entry_count rescue 0), 0]
      end
      json_entry_shape['Goal'] = [timeliness_goal, timeliness_goal, timeliness_goal]

      json_exit_shape = {}
      exit_timeliness.keys.each do |project_name|
        json_exit_shape[project_name] = [0, (exit_timeliness[project_name].sum / exit_timeliness[project_name].size rescue 0), 0]
      end
      if exit_timeliness.keys.count > 1
        json_exit_shape['Average'] = [0, (exit_total / exit_count rescue 0), 0]
      end
      json_exit_shape['Goal'] = [timeliness_goal, timeliness_goal, timeliness_goal]

      entry_support = entry_timeliness_support.map do |project_name, data|
        [
          "timeliness_of_entry_#{project_name.downcase.gsub(' ', '_')}",
          {
            headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Date Recorded'],
            counts: data,
          }
        ]
      end

      exit_support = exit_timeliness_support.map do |project_name, data|
        [
          "timeliness_of_exit_#{project_name.downcase.gsub(' ', '_')}",
          {
            headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Exit Date', 'Date Recorded'],
            counts: data,
          }
        ]
      end
      timeliness_support = (entry_support + exit_support).to_h
      add_answers({
          average_timeliness_of_entry: {
            labels: ["", "Days to Entry", ""],
            data: json_entry_shape,
          },
          average_timeliness_of_exit: {
            labels: ["", "Days to Exit", ""],
            data: json_exit_shape,
          },
        },
        timeliness_support
      )

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
          m[:destination].present? ? "#{m[:destination]}: #{HUD.destination(m[:destination].to_i)}" : ''
        ]
      end
    end

    def calculate_missing_universal_elements
      # NB: requirements vary by element
      # All Clients
      #   FirstName
      #   LastName
      #   SSN
      #   DOB
      #   Race
      #   Ethnicity
      #   Gender
      #   Disabling Condition - in add_missing_enrollment_elements
      #   Physical Disability
      #   Developmental Disability
      #   Chronic Health Condition
      #   HIV/AIDS
      #   Mental Health
      #   Substance Use
      #
      # Adults Only
      #   VeteranStatus
      #
      # Heads of Household and Adults
      #   Residence Prior to Project Entry
      #   Housing Status (at entry)
      #   Income and Sources (at entry)
      #   Non-Cash Benefits (at entry)
      #   Non-Cash Benefits (at exit)
      #   Domestic Violence
      #
      # Leavers
      #   Destination
      #
      # Leavers who are also Heads of Households or Adults
      #   Income and Sources (at exit)
      #
      # Non-DHCD programs

      @refused_ssn_client_ids = Set.new
      @refused_dob_client_ids = Set.new

      missing_first_name = Set.new
      missing_last_name = Set.new
      missing_name = Set.new
      missing_ssn = Set.new
      missing_dob = Set.new
      missing_veteran = Set.new
      missing_ethnicity = Set.new
      missing_race = Set.new
      missing_gender = Set.new

      refused_name = Set.new
      refused_ssn = Set.new
      refused_dob = Set.new
      refused_veteran = Set.new
      refused_ethnicity = Set.new
      refused_race = Set.new
      refused_gender = Set.new

      no_interview_destination = Set.new

      clients.each do |client|

        if client[:first_name].blank? || client[:last_name].blank? || refused?(client[:name_data_quality])
          refused_name << client[:destination_id]
        end

        # NOTE: You can't have both refused and missing SSN or DOB
        # Refused or unknown trumps missing
        if refused?(client[:ssn_data_quality])
          @refused_ssn_client_ids << client[:destination_id]
          refused_ssn << client[:destination_id]
        end
        if refused?(client[:dob_data_quality])
          @refused_dob_client_ids << client[:destination_id]
          refused_dob << client[:destination_id]
        end
        if (client[:veteran_status].blank? || refused?(client[:veteran_status])) && adult?(age(client[:dob]))
          refused_veteran << client[:destination_id]
        end
        if client[:ethnicity].blank? || refused?(client[:ethnicity])
          refused_ethnicity << client[:destination_id]
        end
        if refused?(client[:race_none])
          refused_race << client[:destination_id]
        end
        if refused?(client[:gender])
          refused_gender << client[:destination_id]
        end

        if client[:first_name].blank?
          missing_first_name << client[:destination_id]
        end
        if client[:last_name].blank?
          missing_last_name << client[:destination_id]
        end
        if client[:first_name].blank? || client[:last_name].blank? || missing?(client[:name_data_quality])
          missing_name << client[:destination_id]
        end
        # NOTE: You can't have both refused and missing SSN or DOB
        # Refused or unknown trumps missing
        if !@refused_ssn_client_ids.include?(client[:destination_id]) && (client[:ssn].blank? || missing?(client[:ssn_data_quality]))
          missing_ssn << client[:destination_id]
        end
        if !@refused_dob_client_ids.include?(client[:destination_id]) && (client[:dob].blank? || missing?(client[:dob_data_quality]))
          missing_dob << client[:destination_id]
        end
        if (client[:veteran_status].blank? || missing?(client[:veteran_status])) && adult?(age(client[:dob]))
          missing_veteran << client[:destination_id]
        end
        if client[:ethnicity].blank? || missing?(client[:ethnicity])
          missing_ethnicity << client[:destination_id]
        end
        # If we have no race info, whatsoever
        if missing?(client[:race_none]) && missing_race?(client[:am_ind_ak_native]) && missing_race?(client[:asian]) && missing_race?(client[:black_af_american]) && missing_race?(client[:native_hi_other_pacific]) && missing_race?(client[:white])
          missing_race << client[:destination_id]
        end
        if client[:gender].blank? || missing?(client[:gender])
          missing_gender << client[:destination_id]
        end


        if no_exit_interview?(client[:destination])
          no_interview_destination << client[:destination_id]
        end
      end

      missing_first_name_percent = (missing_first_name.size.to_f/clients.size*100).round(2) rescue 0
      missing_last_name_percent = (missing_last_name.size.to_f/clients.size*100).round(2) rescue 0
      missing_name_percent = (missing_name.size.to_f/clients.size*100).round(2) rescue 0
      missing_ssn_percent = (missing_ssn.size.to_f/clients.size*100).round(2) rescue 0
      missing_dob_percent = (missing_dob.size.to_f/clients.size*100).round(2) rescue 0
      missing_veteran_percent = (missing_veteran.size.to_f/clients.size*100).round(2) rescue 0
      missing_ethnicity_percent = (missing_ethnicity.size.to_f/clients.size*100).round(2) rescue 0
      missing_race_percent = (missing_race.size.to_f/clients.size*100).round(2) rescue 0
      missing_gender_percent = (missing_gender.size.to_f/clients.size*100).round(2) rescue 0
      refused_name_percent = (refused_name.size.to_f/clients.size*100).round(2) rescue 0
      refused_ssn_percent = (refused_ssn.size.to_f/clients.size*100).round(2) rescue 0
      refused_dob_percent = (refused_dob.size.to_f/clients.size*100).round(2) rescue 0
      refused_veteran_percent = (refused_veteran.size.to_f/clients.size*100).round(2) rescue 0
      refused_ethnicity_percent = (refused_ethnicity.size.to_f/clients.size*100).round(2) rescue 0
      refused_race_percent = (refused_race.size.to_f/clients.size*100).round(2) rescue 0
      refused_gender_percent = (refused_gender.size.to_f/clients.size*100).round(2) rescue 0

      answers = {
        total_clients: clients.map{ |m| m[:destination_id] }.uniq.size,
        total_active_clients: active_clients.size,
        total_enterers: enterers.size,
        total_leavers: leavers.size,
        total_households: households.size,
        total_entering_households: entering_households.size,
        total_exiting_households: exiting_households.size,
        missing_first_name: missing_first_name.size,
        missing_last_name: missing_last_name.size,
        missing_name: missing_name.size,
        missing_ssn: missing_ssn.size,
        missing_dob: missing_dob.size,
        missing_veteran: missing_veteran.size,
        missing_ethnicity: missing_ethnicity.size,
        missing_race: missing_race.size,
        missing_gender: missing_gender.size,
        refused_name: refused_name.size,
        refused_ssn: refused_ssn.size,
        refused_dob: refused_dob.size,
        refused_veteran: refused_veteran.size,
        refused_ethnicity: refused_ethnicity.size,
        refused_race: refused_race.size,
        refused_gender: refused_gender.size,
        missing_first_name_percent: missing_first_name_percent,
        missing_last_name_percent: missing_last_name_percent,
        missing_name_percent: missing_name_percent,
        missing_ssn_percent: missing_ssn_percent,
        missing_dob_percent: missing_dob_percent,
        missing_veteran_percent: missing_veteran_percent,
        missing_ethnicity_percent: missing_ethnicity_percent,
        missing_race_percent: missing_race_percent,
        missing_gender_percent: missing_gender_percent,
        refused_name_percent: refused_name_percent,
        refused_ssn_percent: refused_ssn_percent,
        refused_dob_percent: refused_dob_percent,
        refused_veteran_percent: refused_veteran_percent,
        refused_ethnicity_percent: refused_ethnicity_percent,
        refused_race_percent: refused_race_percent,
        refused_gender_percent: refused_gender_percent,
      }
      support = {
        total_clients: {
          headers: universal_element_client_header,
          counts: universal_element_client_counts(clients),
        },
        total_active_clients: {
            headers: universal_element_client_header,
            counts: universal_element_client_counts(active_clients),
        },
        total_enterers: {
            headers: universal_element_client_header,
            counts: universal_element_client_counts(clients.select{|m| enterers.include?(m[:id])}),
        },
        total_leavers: {
          headers: universal_element_client_header,
          counts: universal_element_client_counts(clients.select{|m| leavers.include?(m[:id])}),
        },
        missing_first_name: problem_support_details(missing_first_name, 'missing', 'First Name'),
        missing_last_name: problem_support_details(missing_last_name, 'missing', 'Last Name'),
        missing_name: problem_support_details(missing_name, 'missing', 'Name'),
        missing_ssn: problem_support_details(missing_ssn, 'missing', 'SSN'),
        missing_dob: problem_support_details(missing_dob, 'missing', 'DOB'),
        missing_veteran: problem_support_details(missing_veteran, 'missing', 'Veteran Status'),
        missing_ethnicity: problem_support_details(missing_ethnicity, 'missing', 'Ethnicity'),
        missing_race: problem_support_details(missing_race, 'missing', 'Race'),
        missing_gender: problem_support_details(missing_gender, 'missing', 'Gender'),
        refused_name: problem_support_details(refused_name, 'refused', 'Name'),
        refused_ssn: problem_support_details(refused_ssn, 'refused', 'SSN'),
        refused_dob: problem_support_details(refused_dob, 'refused', 'DOB'),
        refused_veteran: problem_support_details(refused_veteran, 'refused', 'Veteran Status'),
        refused_ethnicity: problem_support_details(refused_ethnicity, 'refused', 'Ethnicity'),
        refused_race: problem_support_details(refused_race, 'refused', 'Race'),
        refused_gender: problem_support_details(refused_gender, 'refused', 'Gender'),
        no_interview_destination: problem_support_details(no_interview_destination, 'missing', 'Exit Destination'),
      }
      add_answers(answers, support)
    end

    def problem_support_details(counts, problem, field)
      {
          headers: ['Client ID', 'Problem', 'Field'],
          counts: counts.map{|m| [m, problem, field]}
      }
    end

    def meets_data_quality_benchmark
      percentages = [
        :missing_first_name_percent,
        :missing_last_name_percent,
        :missing_name_percent,
        :missing_ssn_percent,
        :missing_dob_percent,
        :missing_veteran_percent,
        :missing_ethnicity_percent,
        :missing_race_percent,
        :missing_gender_percent,
        :missing_disabling_condition_percentage,
        :missing_prior_living_situation_percentage,
        :missing_destination_percentage,
        :missing_income_at_entry_percentage,
        :missing_income_at_exit_percentage,
        :refused_name_percent,
        :refused_ssn_percent,
        :refused_dob_percent,
        :refused_veteran_percent,
        :refused_ethnicity_percent,
        :refused_race_percent,
        :refused_gender_percent,
        :refused_disabling_condition_percentage,
        :refused_prior_living_situation_percentage,
        :refused_destination_percentage,
        :refused_income_at_entry_percentage,
        :refused_income_at_exit_percentage,
      ]
      meets_dq_benchmark = report.with_indifferent_access.values_at(*percentages).max < mininum_completeness_threshold rescue false
      add_answers({
        meets_dq_benchmark: meets_dq_benchmark
      })
    end

    def add_missing_enrollment_elements
      client_count = clients.size
      leavers_count = leavers.size
      missing_disabling_condition = Set.new
      missing_prior_living = Set.new
      missing_destination = Set.new
      missing_income_at_entry = Set.new
      missing_income_at_exit = Set.new
      refused_disabling_condition = Set.new
      refused_prior_living = Set.new
      refused_destination = Set.new
      refused_income_at_entry = Set.new
      refused_income_at_exit = Set.new

      enrollments.each do |client_id, enrollments|
        enrollments.each do |enrollment|
          missing_disabling_condition << enrollment[:destination_id] if missing?(enrollment[:disabling_condition])
          missing_prior_living << enrollment[:destination_id] if missing?(enrollment[:residence_prior])
          refused_disabling_condition << enrollment[:destination_id] if refused?(enrollment[:disabling_condition])
          refused_prior_living << enrollment[:destination_id] if refused?(enrollment[:residence_prior])
        end
      end
      leavers.each do |client_id|
        enrollments[client_id].each do |enrollment|
          missing_destination << enrollment[:destination_id] if missing?(enrollment[:destination])
          refused_destination << enrollment[:destination_id] if refused?(enrollment[:destination])
        end
      end

      # Only applies to enrollments started or ended during the report range
      entries.each do |source_client_id, enrollments|
        enrollments.each do |enrollment|
          missing_income_at_entry << source_client_id if missing_income(source_client_id, enrollment, data_collection_stage: 1)
          refused_income_at_entry << source_client_id if refused_income(source_client_id, enrollment, data_collection_stage: 1)
        end
      end
      exits.each do |source_client_id, enrollments|
        enrollments.each do |enrollment|
          missing_income_at_exit << source_client_id if missing_income(source_client_id, enrollment, data_collection_stage: 3)
          refused_income_at_exit << source_client_id if refused_income(source_client_id, enrollment, data_collection_stage: 3)
        end
      end

      missing_disabling_condition_percentage = (missing_disabling_condition.size.to_f/client_count*100).round(2) rescue 0
      missing_prior_living_percentage = (missing_prior_living.size.to_f/client_count*100).round(2) rescue 0
      refused_disabling_condition_percentage = (refused_disabling_condition.size.to_f/client_count*100).round(2) rescue 0
      refused_prior_living_percentage = (refused_prior_living.size.to_f/client_count*100).round(2) rescue 0

      enter_event_count = entries.values.flatten.count
      if enter_event_count == 0
        missing_income_at_entry_percentage = 0
        refused_income_at_entry_percentage = 0
      else
        missing_income_at_entry_percentage = (missing_income_at_entry.size.to_f/enter_event_count*100).round(2) rescue 0
        refused_income_at_entry_percentage = 0 # (refused_income_at_entry.size.to_f/enter_event_count*100).round(2) rescue 0
      end


      exit_event_count = exits.values.flatten.count
      if exit_event_count == 0
        missing_income_at_exit_percentage = 0
        refused_income_at_exit_percentage = 0
      else
        missing_income_at_exit_percentage = (missing_income_at_exit.size.to_f/exit_event_count*100).round(2) rescue 0
        refused_income_at_exit_percentage = 0 # (refused_income_at_exit.size.to_f/exit_event_count*100).round(2) rescue 0
      end

      # missing and refused destinations will be NaN if there are no leavers
      if leavers.count == 0
        missing_destination_percentage = 0
        refused_destination_percentage = 0
      else
        missing_destination_percentage = (missing_destination.size.to_f/leavers_count*100).round(2) rescue 0
        refused_destination_percentage = (refused_destination.size.to_f/leavers_count*100).round(2) rescue 0
      end
      answers = {
        missing_disabling_condition: missing_disabling_condition.size,
        missing_disabling_condition_percentage: missing_disabling_condition_percentage,
        missing_prior_living_situation: missing_prior_living.size,
        missing_prior_living_situation_percentage: missing_prior_living_percentage,
        missing_destination: missing_destination.size,
        missing_destination_percentage: missing_destination_percentage,
        refused_disabling_condition: refused_disabling_condition.size,
        refused_disabling_condition_percentage: refused_disabling_condition_percentage,
        refused_prior_living_situation: refused_prior_living.size,
        refused_prior_living_situation_percentage: refused_prior_living_percentage,
        refused_destination: refused_destination.size,
        refused_destination_percentage: refused_destination_percentage,
        missing_income_at_entry: missing_income_at_entry.size,
        refused_income_at_entry: refused_income_at_entry.size,
        missing_income_at_exit: missing_income_at_exit.size,
        refused_income_at_exit: refused_income_at_exit.size,
        missing_income_at_entry_percentage: missing_income_at_entry_percentage,
        refused_income_at_entry_percentage: refused_income_at_entry_percentage,
        missing_income_at_exit_percentage: missing_income_at_exit_percentage,
        refused_income_at_exit_percentage: refused_income_at_exit_percentage,
      }

      support = {
        missing_disabling_condition: {
          headers: ['Client ID'],
          counts: missing_disabling_condition.map{|m| Array.wrap(m)}
        },
        missing_prior_living_situation: {
          headers: ['Client ID'],
          counts: missing_prior_living.map{|m| Array.wrap(m)}
        },
        missing_destination: {
          headers: ['Client ID'],
          counts: missing_destination.map{|m| Array.wrap(m)}
        },
        refused_disabling_condition: {
          headers: ['Client ID'],
          counts: refused_disabling_condition.map{|m| Array.wrap(m)}
        },
        refused_prior_living_situation: {
          headers: ['Client ID'],
          counts: refused_prior_living.map{|m| Array.wrap(m)}
        },
        refused_destination: {
          headers: ['Client ID'],
          counts: refused_destination.map{|m| Array.wrap(m)}
        },
        missing_income_at_entry: {
          headers: ['Client ID'],
          counts: missing_income_at_entry.map{|m| Array.wrap(m)}
        },
        refused_income_at_entry: {
          headers: ['Client ID'],
          counts: refused_income_at_entry.map{|m| Array.wrap(m)}
        },
        missing_income_at_exit: {
          headers: ['Client ID'],
          counts: missing_income_at_exit.map{|m| Array.wrap(m)}
        },
        refused_income_at_exit: {
          headers: ['Client ID'],
          counts: refused_income_at_exit.map{|m| Array.wrap(m)}
        }
    }

      add_answers(answers, support)
    end

    def add_length_of_stay
      client_count = clients.size
      one_year_enrollments = Set.new
      enrollments.each do |client_id, client_enrollments|
        months_in_project = 0
        client_enrollments.each do |enrollment|
          end_of_enrollment = enrollment[:last_date_in_program] || self.end
          start_of_enrollment = enrollment[:first_date_in_program]
          # count a stay in any month as a month
          months_in_project += (start_of_enrollment..end_of_enrollment).map{|date| [date.year, date.month]}.uniq.count
        end
        one_year_enrollments << client_enrollments.first[:destination_id] if months_in_project > 12
      end
      one_year_enrollments_percentage = (one_year_enrollments.size.to_f/client_count*100).round(2) rescue 0

      answers = {
        one_year_enrollments: one_year_enrollments.size,
        one_year_enrollments_percentage: one_year_enrollments_percentage,
      }
      support = {
        one_year_enrollments: {
          headers: ['Client ID'],
          counts: one_year_enrollments.map{|m| Array.wrap(m)}
        },
      }
      add_answers(answers, support)
    end

    def destination_ph
      ph_destinations = {}
      projects.each do |project|
        ph_destinations[project.ProjectName] = Set.new
      end
      leavers.each do |client_id|
        enrollments[client_id].each do |enrollment|
          # this fixes a bug in bad staging data
          ph_destinations[enrollment[:project_name]] ||= Set.new
          ph_destinations[enrollment[:project_name]] << client_id if HUD.permanent_destinations.include?(enrollment[:destination].to_i)
        end
      end
      ph_destinations_percentage = (ph_destinations.values.flatten.uniq.size.to_f/leavers.size*100).round(2) rescue 0

      json_shape = {
        labels: [ '', "Exit %", '' ],
        data: {},
      }
      ph_destinations.each do |project_name, ids|
        ph_percentage = (ids.count.to_f/leavers.size*100).round(2)
        json_shape[:data][project_name] = [0, ph_percentage, 0]
      end
      json_shape[:data]["Goal"] = [ph_destination_increase_goal, ph_destination_increase_goal, ph_destination_increase_goal]

      answers = {
        ph_destinations: json_shape,
        ph_destinations_percentage: ph_destinations_percentage,
      }

      support = {
        ph_destinations: {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Exit Date'],
          counts: ph_destinations.map do |project_name, ids|
            ids.map do |id|
              client = enrollments[id].sort_by{|h| h[:last_date_in_program]}.last # most recent exit
              [
                id,
                client[:first_name],
                client[:last_name],
                project_name,
                client[:last_date_in_program]
              ]
            end
          end.flatten(1)
        },
      }
      add_answers(answers, support)
    end

    def add_income_answers
      increased_earned = Set.new
      increased_non_cash = Set.new
      increased_overall = Set.new
      increased_earned_twenty_percent = Set.new
      increased_non_cash_twenty_percent = Set.new
      increased_overall_twenty_percent = Set.new
      change_in_earned_percentage = {}
      change_in_non_cash_percentage = {}
      change_in_overall_percentage = {}

      earned_types = [
        :EarnedAmount,
      ]
      non_cash_types = [
        :UnemploymentAmount,
        :SSIAmount,
        :SSDIAmount,
        :VADisabilityServiceAmount,
        :VADisabilityNonServiceAmount,
        :PrivateDisabilityAmount,
        :WorkersCompAmount,
        :TANFAmount,
        :GAAmount,
        :SocSecRetirementAmount,
        :PensionAmount,
        :ChildSupportAmount,
        :AlimonyAmount,
        :OtherIncomeAmount
      ]
      all_income_types = earned_types + non_cash_types

      incomes.each do |client_id, income_assessments|
        next if income_assessments.count < 2
        first_assessment = income_assessments.first
        last_assessment = income_assessments.last
        last_earned_income = last_assessment.values_at(*earned_types).compact.sum
        first_earned_income = first_assessment.values_at(*earned_types).compact.sum
        last_non_cash_income = last_assessment.values_at(*non_cash_types).compact.sum
        first_non_cash_income = first_assessment.values_at(*non_cash_types).compact.sum
        last_total_income = last_assessment.values_at(*all_income_types).compact.sum
        first_total_income = first_assessment.values_at(*all_income_types).compact.sum

        increased_earned << client_id if last_earned_income >= first_earned_income
        increased_earned_twenty_percent << client_id if increased_twenty_percent?(last_earned_income, first_earned_income)
        # you might also have an increase that doesn't contain the value details
        increased_earned << client_id if first_earned_income != 1 && last_earned_income == 1
        change_in_earned_percentage[client_id] = income_increase(change_in_earned_percentage[client_id], last_earned_income, first_earned_income, last_assessment)

        increased_non_cash << client_id if last_non_cash_income >= first_non_cash_income
        increased_non_cash_twenty_percent << client_id if increased_twenty_percent?(last_non_cash_income, first_non_cash_income)
        change_in_non_cash_percentage[client_id] = income_increase(change_in_non_cash_percentage[client_id], last_non_cash_income, first_non_cash_income, last_assessment)

        increased_overall << client_id if last_total_income >= first_total_income
        increased_overall_twenty_percent << client_id if increased_twenty_percent?(last_total_income, first_total_income)
        change_in_overall_percentage[client_id] = income_increase(change_in_overall_percentage[client_id], last_total_income, first_total_income, last_assessment)

      end

      increased_earned_percentage = (increased_earned.size.to_f/clients.size*100).round(2) rescue 0
      increased_earned_twenty_percent_percentage = (increased_earned_twenty_percent.size.to_f/clients.size*100).round(2) rescue 0
      increased_non_cash_percentage = (increased_non_cash.size.to_f/clients.size*100).round(2) rescue 0
      increased_non_cash_twenty_percent_percentage = (increased_non_cash_twenty_percent.size.to_f/clients.size*100).round(2) rescue 0
      increased_overall_percentage = (increased_overall.size.to_f/clients.size*100).round(2) rescue 0
      increased_overall_twenty_percent_percentage = (increased_overall_twenty_percent.size.to_f/clients.size*100).round(2) rescue 0

      json_shape = {
          labels: [ "Increased or Retained", "20% Increase" ],
          data: {
            "Earned Income": [ increased_earned_percentage, increased_earned_twenty_percent_percentage],
            "Non-Cash Income": [ increased_non_cash_percentage, increased_non_cash_twenty_percent_percentage ],
            "Overall Income": [ increased_overall_percentage, increased_overall_twenty_percent_percentage ],
            "Goal": [ income_increase_goal, income_increase_goal ],
          }
      }

      answers = {
        client_income: json_shape,

        increased_earned: increased_earned.size,
        increased_non_cash: increased_non_cash.size,
        increased_overall: increased_overall.size,
        increased_earned_percentage: increased_earned_percentage,
        increased_non_cash_percentage: increased_non_cash_percentage,
        increased_overall_percentage: increased_overall_percentage,
      }

      support = {
        'Earned Income'.downcase.gsub(' ', '_') => {
          headers: income_support_header,
          counts: increased_earned.map{|m| income_support(m, change_in_earned_percentage)}
        },
        'Non-Cash Income'.downcase.gsub(' ', '_') => {
          headers: income_support_header,
          counts: increased_non_cash.map{|m| income_support(m, change_in_non_cash_percentage)}
        },
        'Overall Income'.downcase.gsub(' ', '_') => {
          headers: income_support_header,
          counts: increased_overall.map{|m| income_support(m, change_in_overall_percentage)}
        },
        'Earned Income 20'.downcase.gsub(' ', '_') => {
          headers: income_support_header,
          counts: increased_earned_twenty_percent.map{|m| income_support(m, change_in_earned_percentage)}
        },
        'Non-Cash Income 20'.downcase.gsub(' ', '_') => {
          headers: income_support_header,
          counts: increased_non_cash_twenty_percent.map{|m| income_support(m, change_in_non_cash_percentage)}
        },
        'Overall Income 20'.downcase.gsub(' ', '_') => {
          headers: income_support_header,
          counts: increased_overall_twenty_percent.map{|m| income_support(m, change_in_overall_percentage)}
        },
      }
      add_answers(answers, support)

    end

    def income_support_header
      ['Client ID', 'First Name', 'Last Name', 'Project Name', '% Change']
    end

    def income_support(client_id, changes)
      data = changes[client_id]
      [ client_id, data[:first_name], data[:last_name], data[:project_name], data[:change] ]
    end

    def income_increase(current_values, last_earned_income, first_earned_income, assessment)
      result = current_values || {}

      enrollment = enrollments[assessment[:client_id]].detect{|e| e[:enrollment_id] == assessment[:enrollment_id]}
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

    def add_capacity_answers
      total_services_provided = service_scope.
        service_within_date_range(start_date: self.start, end_date: self.end).
        distinct.
        pluck(she_t[:client_id].as('client_id').to_sql, shs_t[:date].as('date').to_sql).
        count
      days_served = (self.end - self.start).to_i
      average_usage = (total_services_provided.to_f/days_served).round(2) rescue 0
      average_stay_length = (total_services_provided.to_f/clients.size).round(2) rescue 0
      capacity = if beds > 0
        (average_usage.to_f/beds*100).round(2) rescue 0
      else
        0
      end
      add_answers({
        services_provided: total_services_provided,
        days_of_service: days_served,
        average_daily_usage: average_usage,
        average_stay_length: average_stay_length,
        capacity_percentage: capacity,
      })
    end

    def report_columns
      {
        total_clients: {
          title: 'Clients included'
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
          title:"Meets DQ Benchmark (all missing/refused < #{mininum_completeness_threshold}%)",
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
      @filter ||= ::Filters::DateRange.new(start: self.start, end: self.end)
    end

    def active_clients
      @active_client ||= begin
        service_history_enrollment_scope.
          service_within_date_range(start_date: self.start, end_date: self.end).
          joins(:client, :project).
          where(Project: {id: projects.map(&:id)}).
          distinct.
          pluck(*client_columns.values.map { |column| Arel.sql(column) }).
          map do |row|
            Hash[client_columns.keys.zip(row)]
        end
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
            if enrollment[:first_date_in_program].present? && enrollment[:first_date_in_program] >= self.start
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
        open_between(start_date: self.start, end_date: self.end).
        in_project(projects.map(&:id)).
        distinct.
        pluck(:household_id)
    end

    def entering_households
      @entering_households ||= begin
        entries = {}
        enrollments.each do |client_id, client_enrollments|
          client_enrollments.each do |enrollment|
            if enrollment[:first_date_in_program].present? && enrollment[:first_date_in_program] >= self.start
              household = enrollment[:household_id]
              entries[household] ||= []
              entries[household] << enrollment
            end
          end
        end
        entries
      end
    end

    def exiting_households
      @exiting_households ||= begin
        exits = {}
        enrollments.each do |client_id, client_enrollments|
          client_enrollments.each do |enrollment|
            if enrollment[:last_date_in_program].present? && enrollment[:last_date_in_program] <= self.end
              household = enrollment[:household_id]
              exits[household] ||= []
              exits[household] << enrollment
            end
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
        data_collection_stage: data_collection_stage
      )

      if incomes.present?
        incomes.each do |income|
          return true if income[:IncomeFromAnySource] == 99 || # Data Not Collected
            (income[:TotalMonthlyIncome] == nil && income[:IncomeFromAnySource] == 0) ||
            (income[:TotalMonthlyIncome] == nil && income[:IncomeFromAnySource] == 1)
        end
        return false
      else
        return true
      end
    end

    def refused_income(source_client_id, enrollment, data_collection_stage:)
      incomes = income_assessment_at_stage_for(
          source_client_id: source_client_id,
          enrollment_id: enrollment[:enrollment_id],
          data_collection_stage: data_collection_stage
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
