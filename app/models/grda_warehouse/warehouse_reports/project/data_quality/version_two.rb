###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionTwo < Base
    MISSING_THRESHOLD = 10
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
        :add_missing_values,
        :add_enrolled_length_of_stay,
        :add_clients_dob_enrollment_date,
        :add_night_by_night_missing,
        :add_service_after_close,
        :add_individuals_at_family_projects,
        :add_families_at_individual_projects,
        :add_enrollments_with_no_service,
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
        '0 days' => (0..0),
        '1 week or less' => (1..6),
        '1 month or less' => (7..30),
        '1 to 3 months'  => (31..90),
        '3 to 6 months' => (91..180),
        '6 to 9 months' => (181..271),
        '9 to 12 months' => (272..364),
        '1 year to 18 months' => (365..545),
        '18 months - 2 years' => (546..729),
        '2 - 5 years' => (730..1825),
        '5 years or more' => (1826..1.0/0),
      }
    end

    def set_project_metadata
      agency_names = projects.map(&:organization).map(&:OrganizationName).compact
      project_names = projects.map(&:ProjectName)
      monitoring_ranges = []
      monitoring_date_range_present = false
      grant_ids = []
      coc_program_components = projects.map do |project|
        ::HUD.project_type(project.ProjectType)
      end
      target_populations = projects.map do |project|
        ::HUD.target_population(project.TargetPopulation) || nil
      end.compact

      projects.flat_map(&:funders).each do |funder|
        monitoring_ranges << "#{funder&.StartDate} - #{funder&.EndDate}" if funder.StartDate.present? || funder.EndDate.present?
        monitoring_date_range_present = true if funder&.StartDate.present? && funder&.EndDate.present?
        grant_ids << funder.GrantID if funder.GrantID.present?
      end

      add_answers({
        agency_name: agency_names.join(', '),
        project_name: project_names.join(', '),
        monitoring_date_range: monitoring_ranges.join(', '),
        monitoring_date_range_present: monitoring_date_range_present,
        # funding_year: funder.operating_year,
        grant_id: grant_ids.join(', '),
        coc_program_component: coc_program_components.join(', '),
        target_population: target_populations.join(', '),
      })
    end

    def add_enrollments_with_no_service
      empty_enrollments = {}
      projects.each do |project|
        if project.TrackingMethod == 3
          enrollments_in_project = enrollments_for_project(
            project.ProjectID, project.data_source_id
          )&.values&.flatten(1)
          if enrollments_in_project.present? && enrollments_in_project.any?
            enrollments_in_project = enrollments_in_project.group_by do |row|
              [row[:data_source_id], row[:enrollment_group_id]]
            end
            enrollment_groups = enrollments_in_project.keys.map(&:last)
            services = GrdaWarehouse::Hud::Service.where(EnrollmentID: enrollment_groups).distinct.pluck(:data_source_id, :EnrollmentID)
            empties = enrollments_in_project.keys - services
            empty_enrollments[project.id] = enrollments_in_project.values_at(*empties)
          else
            empty_enrollments[project.id] = []
          end
        else
          empty_enrollments[project.id] = []
        end
      end
      answers = {
        enrollments_with_no_service: {}
      }
      support = {}
      empty_enrollments.each do |project_id, ens|
        # NOTE: we are counting enrollments not distinct clients
        answers[:enrollments_with_no_service][project_id] = ens.count
        support["enrollments_with_no_service_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date'],
          counts: ens.flatten(1).
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
        }
      end
      add_answers(answers, support)
    end

    def add_individuals_at_family_projects
      individuals = {}
      projects.each do |project|
        if project.serves_families?
          enrollments_in_project = enrollments_for_project(
            project.ProjectID, project.data_source_id
          )&.values&.flatten(1)
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
      individuals.each do |project_id, clients|
        answers[:individuals_at_family_projects][project_id] = clients.count
        support["individuals_at_family_projects_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date'],
          counts: clients.map do |service|
            client_id = destination_id_for_client(service[:id])
            [
              client_id,
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

    def add_families_at_individual_projects
      families = {}
      projects.each do |project|
        if project.serves_only_individuals?
          enrollments_in_project = enrollments_for_project(project.ProjectID, project.data_source_id)&.values&.flatten(1)
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
            client_id = destination_id_for_client(service[:id])
            [
              client_id,
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
      service_after_close.each do |project_id, clients|
        support["service_after_close_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: clients.map do |service|
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
        }
      end
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
      missing_nights.each do |project_id, clients|
        support["missing_nights_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'Project', 'Entry Date', 'Exit Date', 'Last Date Served'],
          counts: clients.map do |service|
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
        }
      end
      add_answers(answers, support)
    end

    def add_clients_dob_enrollment_date
      dob_entry = {}
      projects.each do |project|
        dob_entry[project.id] ||= Set.new
        enrollments_in_project = enrollments_for_project(project.ProjectID, project.data_source_id)&.values&.flatten(1)
        if enrollments_in_project.present? && enrollments_in_project.any?
          enrollments_in_project.each do |enrollment|
            if enrollment[:dob].present? && enrollment[:dob].to_date >= enrollment[:first_date_in_program].to_date
              dob_entry[project.id] << [
                destination_id_for_client(enrollment[:id]),
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
      dob_entry.each do |project_id, clients|
        support["incorrect_dob_#{project_id}"] = {
          headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'Entry Date', 'Project'],
          counts: clients.to_a
        }
      end
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
      totals = {
        buckets: self.class.length_of_stay_buckets.map do |title, range|
          [range, Set.new]
        end.to_h,
        counts: {
          total_days: 0,
          average_days: 0,
        },
      }

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
        project_counts[project.id][:counts] = counts.map{|range,services| [range, services.count]}.to_h
        project_counts[project.id][:buckets] = counts
      end
      totals[:counts][:average] = (totals[:counts][:total_days].to_f / (self.end - self.start).to_i).round
      totals[:counts][:buckets] = totals[:buckets].map{|range,services| [range,services.count]}.to_h
      answers = {
        enrolled_length_of_stay: {
          projects: project_counts,
          totals: totals[:counts],
        }
      }
      support = {}
      project_counts.each do |project_id, buckets|
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

      projects.each do |project|
        counts = {}
        self.class.missing_refused_names.keys.each do |word|
          counts["missing_#{word}"] = Set.new
          counts["refused_#{word}"] = Set.new
          counts["unknown_#{word}"] = Set.new
        end
        clients_in_project = clients_for_project(project.id)
        clients_in_project.each do |client|
          counts = add_missing_demo(client: client, counts: counts)
          counts = add_refused_demo(client: client, counts: counts)
          counts = add_unknown_demo(client: client, counts: counts)
        end
        enrollments_in_project = enrollments_for_project(project.ProjectID, project.data_source_id)
        if enrollments_in_project.present? && enrollments_in_project.any?
          enrollments_in_project.each do |client_id, enrollments|
            if enrollments.present?
              enrollments.each do |enrollment|
                counts = add_missing_enrollment(client_id: client_id, enrollment: enrollment, counts: counts)
                counts = add_refused_enrollment(client_id: client_id, enrollment: enrollment, counts: counts)
                counts = add_unknown_enrollment(client_id: client_id, enrollment: enrollment, counts: counts)
              end
            end
            leavers_in_project = leavers_for_project(project.ProjectID, project.data_source_id)
            if leavers_in_project.present? && leavers_in_project.any?
              leavers_in_project.each do |client_id|
                enrollments_in_project[client_id].each do |enrollment|
                  counts = add_missing_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                  counts = add_refused_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                  counts = add_unknown_destinations(client_id: client_id, enrollment: enrollment, counts: counts)
                end
              end
            end
          end
        end
        counts.each do |key, value|
          totals[key] += value
          answers[:project_missing][project.id] ||= {}
          answers[:project_missing][project.id][key] = value.size
          answers[:project_missing][project.id]["#{key}_percentage"] = in_percentage(value.size, clients_in_project.size)
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
        answers[:project_missing][:totals]["#{key}_percentage"] = in_percentage(value.size, clients.size)
        if ! [:total_open_enrollments, :total_missing, :clients_served_during_range].include?(key)
          support["project_missing_totals_#{key}"] = {
            headers: self.class.missing_refused_names[header_key],
            counts: value.to_a
          }
        end
      end

      add_answers(answers, support)
    end

    def self.missing_refused_names
      {
        name: ['Client ID', 'First Name', 'Last Name', 'Name Data Quality'],
        ssn: ['Client ID', 'First Name', 'Last Name', 'SSN', 'SSN Quality'],
        dob: ['Client ID', 'First Name', 'Last Name', 'DOB', 'DOB Quality'],
        veteran: ['Client ID', 'First Name', 'Last Name', 'Veteran Status'],
        ethnicity: ['Client ID', 'First Name', 'Last Name', 'Ethnicity'],
        race: ['Client ID', 'First Name', 'Last Name', 'Race None', 'AmIndAKNative', 'Asian', 'Black or African American', 'Native HI Other Pacific', 'White'],
        gender: ['Client ID', 'First Name', 'Last Name', 'Gender'],
        disabling_condition: ['Client ID', 'First Name', 'Last Name', 'Disability Type', 'Disability Response'],
        residence_prior: ['Client ID', 'First Name', 'Last Name', 'Prior Residence'],
        destination: ['Client ID', 'First Name', 'Last Name', 'Destination'],
        # last_permanent_zip: ['Client ID', 'First Name', 'Last Name', 'Last Permanent Zip'],
      }
    end

    def base_colums_for_support enrollment
      [
        enrollment[:id],
        enrollment[:first_name],
        enrollment[:last_name],
      ]
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

    def add_missing_enrollment client_id:, enrollment:, counts:
      disabilities = disabilities_for_enrollment(enrollment)
      if missing_disability?(disabilities)
        counts['missing_disabling_condition'] += columns_for_disabling_condition_support(enrollment, disabilities, 99)
      end
      if missing?(enrollment[:residence_prior]) && adult?(enrollment[:age])  && enrollment[:head_of_household]
        counts['missing_residence_prior'] << columns_for_residence_prior_support(enrollment)
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
        counts['refused_residence_prior'] << columns_for_residence_prior_support(enrollment)
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
        counts['unknown_residence_prior'] << columns_for_residence_prior_support(enrollment)
      end
      # if unknown?(enrollment[:last_permanent_zip])
      #   counts['unknown_last_permanent_zip'] << columns_for_last_permanent_zip_support(enrollment)
      # end
      return counts
    end

    def add_missing_demo client:, counts:
      alternate_clients = source_clients_for_source_client(source_client_id: client[:destination_id], data_source_id: client[:data_source_id])
      alternate_all_adults = alternate_clients.map{|m| adult?(age(m[:dob]))}.all?
      if alternate_clients.map{|m| m[:first_name]}.all?(&:blank?) || alternate_clients.map{|m| m[:last_name]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:name_data_quality])}.all?
        counts['missing_name'] << columns_for_name_support(client)
      end
      if alternate_clients.map{|m| m[:ssn]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:ssn_data_quality])}.all?
        counts['missing_ssn'] << columns_for_ssn_support(client)
      end
      if alternate_clients.map{|m| m[:dob]}.all?(&:blank?) || alternate_clients.map{|m| missing?(m[:dob_data_quality])}.all?
        counts['missing_dob'] << columns_for_dob_support(client)
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
      if alternate_clients.map{|m| refused?(m[:ssn_data_quality])}.all?
        counts['refused_ssn'] << columns_for_ssn_support(client)
      end
      if alternate_clients.map{|m| refused?(m[:dob_data_quality])}.all?
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
        counts['unknown_ssn'] << columns_for_ssn_support(client)
      end
      if alternate_clients.map{|m| unknown?(m[:dob_data_quality])}.all?
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

    def add_bed_utilization
      bed_utilization = []
      support = {}
      totals = {counts: Hash.new(0), data: Hash.new(Set.new)}

      client_columns = [:client_id, c_t[:FirstName].as('first_name').to_sql, c_t[:LastName].as('last_name').to_sql]
      filter = ::Filters::DateRange.new(start: self.start, end: self.end)
      projects.each do |project|
        counts = {}
        data = {}
        counts[:capacity] = project.inventories.within_range(filter.range).map{|i| i[:BedInventory] || 0}.sum
        total_count = project.service_history.service.
        joins(:client, :project).
        where(Project: {id: project.id}).
        where(date: filter.range).count
        data[:average_daily] = project.service_history.service.
          joins(:client, :project).
          where(Project: {id: project.id}).
          where(date: filter.range).
          distinct.
          pluck(*client_columns)
          counts[:average_daily] = total_count / filter.range.count rescue 0
        data[:first_of_month] = project.service_history.service.
          joins(:client, :project).
          where(Project: {id: project.id}).
          where(date: filter.first).
          distinct.
          pluck(*client_columns)
          counts[:first_of_month] = data[:first_of_month].count
        data[:fifteenth_of_month] = project.service_history.service.
          joins(:client, :project).
          where(Project: {id: project.id}).
          where(date: filter.ides).
          distinct.
          pluck(*client_columns)
        counts[:fifteenth_of_month] = data[:fifteenth_of_month].count
        data[:last_of_month] = project.service_history.service.
          joins(:client, :project).
          where(Project: {id: project.id}).
          where(date: filter.last).
          distinct.
          pluck(*client_columns)
        counts[:last_of_month] = data[:last_of_month].count
        project_counts = {
          id: project.id,
          name: project.ProjectName,
          project_type: project[GrdaWarehouse::Hud::Project.project_type_column],
        }.merge(counts)
        totals[:counts][:capacity] += counts[:capacity]
        self.class.bed_utilization_attributes.each do |attr|
          project_counts["#{attr}_percentage"] = in_percentage(counts[attr], counts[:capacity])
          totals[:counts][attr] += counts[attr]
          totals[:data][attr] += data[attr]
          support["bed_utilization_#{project.id}_#{attr}"] = {
            headers: ['Client ID', 'First Name', 'Last Name'],
            counts: data[attr]
          }
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

      add_answers(
        {
          bed_utilization: bed_utilization,
          bed_utilization_totals: totals,
        },
        support
      )

    end

    def self.bed_utilization_attributes
      [
        :average_daily,
        :first_of_month,
        :fifteenth_of_month,
        :last_of_month,
      ]
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


    def calculate_missing_universal_elements
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

      clients.each do |client|
        if client[:first_name].blank? || client[:last_name].blank? || missing?(client[:name_data_quality])
          missing_name << client[:destination_id]
        end
        if client[:ssn].blank? || missing?(client[:ssn_data_quality])
          missing_ssn << client[:destination_id]
        end
        if client[:dob].blank? || missing?(client[:dob_data_quality])
          missing_dob << client[:destination_id]
        end
        if (client[:veteran_status].blank? || missing?(client[:veteran_status])) && adult?(age(client[:dob]))
          missing_veteran << client[:destination_id]
        end
        if client[:ethnicity].blank? || missing?(client[:ethnicity])
          missing_ethnicity << client[:destination_id]
        end
        # If we have no race info, whatsoever
        if missing?(client[:race_none]) && missing?(client[:am_ind_ak_native]) && missing?(client[:asian]) && missing?(client[:black_af_american]) && missing?(client[:native_hi_other_pacific]) && missing?(client[:white])
          missing_race << client[:destination_id]
        end
        if client[:gender].blank? || missing?(client[:gender])
          missing_gender << client[:destination_id]
        end

        if client[:first_name].blank? || client[:last_name].blank? || refused?(client[:name_data_quality])
          refused_name << client[:destination_id]
        end
        if client[:ssn].blank? || refused?(client[:ssn_data_quality])
          refused_ssn << client[:destination_id]
        end
        if client[:dob].blank? || refused?(client[:dob_data_quality])
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
        if client[:gender].blank? || refused?(client[:gender])
          refused_gender << client[:destination_id]
        end
      end

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
        total_clients: clients.size,
        total_leavers: leavers.size,
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
          headers: ['Client ID', 'First Name', 'Last Name'],
          counts: clients.map{|m| [m[:destination_id], m[:first_name], m[:last_name]]},
        },
        total_leavers: {
          headers: ['Client ID'],
          counts: clients.select{|m| leavers.include?(m[:id])}.map{|m| [m[:destination_id], m[:first_name], m[:last_name]]},
        },
        missing_name: {
          headers: ['Client ID'],
          counts: missing_name.map{|m| Array.wrap(m)}
        },
        missing_ssn: {
          headers: ['Client ID'],
          counts: missing_ssn.map{|m| Array.wrap(m)}
        },
        missing_dob: {
          headers: ['Client ID'],
          counts: missing_dob.map{|m| Array.wrap(m)}
        },
        missing_veteran: {
          headers: ['Client ID'],
          counts: missing_veteran.map{|m| Array.wrap(m)}
        },
        missing_ethnicity: {
          headers: ['Client ID'],
          counts: missing_ethnicity.map{|m| Array.wrap(m)}
        },
        missing_race: {
          headers: ['Client ID'],
          counts: missing_race.map{|m| Array.wrap(m)}
        },
        missing_gender: {
          headers: ['Client ID'],
          counts: missing_gender.map{|m| Array.wrap(m)}
        },
        refused_name: {
          headers: ['Client ID'],
          counts: refused_name.map{|m| Array.wrap(m)}
        },
        refused_ssn: {
          headers: ['Client ID'],
          counts: refused_ssn.map{|m| Array.wrap(m)}
        },
        refused_dob: {
          headers: ['Client ID'],
          counts: refused_dob.map{|m| Array.wrap(m)}
        },
        refused_veteran: {
          headers: ['Client ID'],
          counts: refused_veteran.map{|m| Array.wrap(m)}
        },
        refused_ethnicity: {
          headers: ['Client ID'],
          counts: refused_ethnicity.map{|m| Array.wrap(m)}
        },
        refused_race: {
          headers: ['Client ID'],
          counts: refused_race.map{|m| Array.wrap(m)}
        },
        refused_gender: {
          headers: ['Client ID'],
          counts: refused_gender.map{|m| Array.wrap(m)}
        },
      }
      add_answers(answers, support)
    end

    def meets_data_quality_benchmark
      percentages = [
        :missing_name_percent,
        :missing_ssn_percent,
        :missing_dob_percent,
        :missing_veteran_percent,
        :missing_ethnicity_percent,
        :missing_race_percent,
        :missing_gender_percent,
        :missing_disabling_condition_percentage,
        :missing_prior_living_percentage,
        :missing_destination_percentage,
        :refused_name_percent,
        :refused_ssn_percent,
        :refused_dob_percent,
        :refused_veteran_percent,
        :refused_ethnicity_percent,
        :refused_race_percent,
        :refused_gender_percent,
        :refused_disabling_condition_percentage,
        :refused_prior_living_percentage,
        :refused_destination_percentage,
      ]
      meets_dq_benchmark = report.with_indifferent_access.values_at(*percentages).max < MISSING_THRESHOLD rescue false
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
      refused_disabling_condition = Set.new
      refused_prior_living = Set.new
      refused_destination = Set.new
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

      missing_disabling_condition_percentage = (missing_disabling_condition.size.to_f/client_count*100).round(2) rescue 0
      missing_prior_living_percentage = (missing_prior_living.size.to_f/client_count*100).round(2) rescue 0
      refused_disabling_condition_percentage = (refused_disabling_condition.size.to_f/client_count*100).round(2) rescue 0
      refused_prior_living_percentage = (refused_prior_living.size.to_f/client_count*100).round(2) rescue 0

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
        missing_prior_living: missing_prior_living.size,
        missing_prior_living_percentage: missing_prior_living_percentage,
        missing_destination: missing_destination.size,
        missing_destination_percentage: missing_destination_percentage,
        refused_disabling_condition: refused_disabling_condition.size,
        refused_disabling_condition_percentage: refused_disabling_condition_percentage,
        refused_prior_living: refused_prior_living.size,
        refused_prior_living_percentage: refused_prior_living_percentage,
        refused_destination: refused_destination.size,
        refused_destination_percentage: refused_destination_percentage,
      }

      support = {
        missing_disabling_condition: {
          headers: ['Client ID'],
          counts: missing_disabling_condition.map{|m| Array.wrap(m)}
        },
        missing_prior_living: {
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
        refused_prior_living: {
          headers: ['Client ID'],
          counts: refused_prior_living.map{|m| Array.wrap(m)}
        },
        refused_destination: {
          headers: ['Client ID'],
          counts: refused_destination.map{|m| Array.wrap(m)}
        },
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
      ph_destinations = Set.new
      leavers.each do |client_id|
        enrollments[client_id].each do |enrollment|
          ph_destinations << enrollment[:destination_id] if HUD.permanent_destinations.include?(enrollment[:destination].to_i)
        end
      end
      ph_destinations_percentage = (ph_destinations.size.to_f/leavers.size*100).round(2) rescue 0
      answers = {
        ph_destinations: ph_destinations.size,
        ph_destinations_percentage: ph_destinations_percentage,
      }

      support = {
        ph_destinations: {
          headers: ['Client ID'],
          counts: ph_destinations.map{|m| Array.wrap(m)}
        },
      }
      add_answers(answers, support)
    end

    def add_income_answers
      increased_earned = Set.new
      increased_non_cash = Set.new
      increased_overall = Set.new
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
        # you might also have an increase that doesn't contain the value details
        increased_earned << client_id if first_earned_income != 1 && last_earned_income == 1
        increased_non_cash << client_id if last_non_cash_income >= first_non_cash_income
        increased_overall << client_id if last_total_income >= first_total_income
      end

      increased_earned_percentage = (increased_earned.size.to_f/clients.size*100).round(2) rescue 0
      increased_non_cash_percentage = (increased_non_cash.size.to_f/clients.size*100).round(2) rescue 0
      increased_overall_percentage = (increased_overall.size.to_f/clients.size*100).round(2) rescue 0

      answers = {
        increased_earned: increased_earned.size,
        increased_non_cash: increased_non_cash.size,
        increased_overall: increased_overall.size,
        increased_earned_percentage: increased_earned_percentage,
        increased_non_cash_percentage: increased_non_cash_percentage,
        increased_overall_percentage: increased_overall_percentage,
      }
      support = {
        increased_earned: {
          headers: ['Client ID'],
          counts: increased_earned.map{|m| Array.wrap(m)}
        },
        increased_non_cash: {
          headers: ['Client ID'],
          counts: increased_non_cash.map{|m| Array.wrap(m)}
        },
        increased_overall: {
          headers: ['Client ID'],
          counts: increased_overall.map{|m| Array.wrap(m)}
        },
      }
      add_answers(answers, support)

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
          title:"Meets DQ Benchmark (all missing/refused < #{MISSING_THRESHOLD}%)",
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


  end
end
