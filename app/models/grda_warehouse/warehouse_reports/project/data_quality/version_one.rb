module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionOne < Base
    MISSING_THRESHOLD = 10
    def run!
      start_report()
      set_project_metadata()
      set_bed_coverage_data()
      calculate_missing_universal_elements()
      add_missing_enrollment_elements()
      add_agency_entering_data()
      add_length_of_stay()
      destination_ph()
      add_income_answers()
      add_capacity_answers()
      meets_data_quality_benchmark()
      finish_report()
    end

    def report_columns
      {
        total_clients: {
          title:'Clients included'
        },
        total_leavers: {
          title: 'Leavers',
        },
        agency_name: {
          title: 'Agency name',
        },
        project_name: {
          title: 'Project name',
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
          title: 'Is the agency entering the required data/descriptor touch-points into HMI},
          S for this project?',
          callback: :boolean,
        },
        bed_coverage: {
          title: 'Bed coverage',
        },
        bed_coverage_percent: {
          title:'Bed coverage',
          callback: :percent,
        },
        missing_name_percent: {
          title:'Missing names',
          callback: :percent,
        },
        missing_ssn_percent: {
          title:'Missing SSN',
          callback: :percent,
        },
        missing_dob_percent: {
          title:'Missing DOB',
          callback: :percent,
        },
        missing_veteran_percent: {
          title:'Missing veteran status',
          callback: :percent,
        },
        missing_ethnicity_percent: {
          title:'Missing ethnicity',
          callback: :percent,
        },
        missing_race_percent: {
          title:'Missing race',
          callback: :percent,
        },
        missing_gender_percent: {
          title:'Missing gender',
          callback: :percent,
        },
        missing_disabling_condition_percentage: {
          title: 'Missing disabling condition',
          callback: :percent
        },
        missing_prior_living_percentage: {
          title: 'Missing prior living',
          callback: :percent
        },
        missing_destination_percentage: {
          title: 'Missing destination',
          callback: :percent
        },
        refused_name_percent: {
          title:'Refused name',
          callback: :percent,
        },
        refused_ssn_percent: {
          title:'Refused SSN',
          callback: :percent,
        },
        refused_dob_percent: {
          title:'Refused DOB',
          callback: :percent,
        },
        refused_veteran_percent: {
          title:'Refused veteran status',
          callback: :percent,
        },
        refused_ethnicity_percent: {
          title:'Refused ethnicity',
          callback: :percent,
        },
        refused_race_percent: {
          title:'Refused race',
          callback: :percent,
        },
        refused_gender_percent: {
          title:'Refused gender',
          callback: :percent,
        },
        refused_disabling_condition_percentage: {
          title: 'Refused disabling condition',
          callback: :percent
        },
        refused_prior_living_percentage: {
          title: 'Refused prior living',
          callback: :percent
        },
        refused_destination_percentage: {
          title: 'Refused destination',
          callback: :percent
        },
        meets_dq_benchmark: {
          title:"Meets DQ Benchmark (all missing/refused < #{MISSING_THRESHOLD}%)",
          callback: :boolean,
        },
        one_year_enrollments: {
          title:'Enrollments lasting 12 or more months',
        },
        one_year_enrollments_percentage: {
          title:'Clients with enrollments lasting 12 or more months',
          callback: :percent,
        },
        ph_destinations_percentage: {
          title:'Leavers who exited to PH',
        },
        increased_earned: {
          title:'Clients with increased earned income',
        },
        increased_earned_percentage: {
          title:'Percentage of clients who had increased earned income',
          callback: :percent,
        },
        increased_non_cash: {
          title:'Clients with increased non-cash income',
        },
        increased_non_cash_percentage: {
          title:'Percentage of clients who had increased non-cash income',
          callback: :percent,
        },
        increased_overall: {
          title:'Clients with increased overall income',
        },
        increased_overall_percentage: {
          title:'Percentage of clients who had increased total income',
          callback: :percent,
        },
        services_provided: {
          title:'Number of service events',
        },
        days_of_service: {
          title:'Number of days in selected range',
        },
        average_daily_usage: {
          title:'Average daily usage',
        },
        capacity_percentage: {
          title:'Percentage of beds in use, on average',
          callback: :percent,
        },
      }

    end


    def set_project_metadata
      funder = project.funders.last
      add_answers({
        agency_name: project.organization.OrganizationName,
        project_name: project.ProjectName,
        monitoring_date_range: "#{funder&.StartDate} - #{funder&.EndDate}",
        monitoring_date_range_present: funder&.StartDate.present? && funder&.EndDate.present?,
        # funding_year: funder.operating_year,
        grant_id: funder&.GrantID,
        coc_program_component: ::HUD.project_type(project.ProjectType),
        target_population: ::HUD.target_population(project.TargetPopulation) || '',
      })
    end

    def set_bed_coverage_data
      hmis_beds = project.inventories.map(&:HMISParticipatingBeds).reduce(:+) || 0
      
      bed_coverage = 0 
      bed_coverage_percent = 0
      if hmis_beds > 0
        bed_coverage = "#{beds} / #{hmis_beds}"
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
          missing_name << client[:id]
        end
        if client[:ssn].blank? || missing?(client[:ssn_data_quality])
          missing_ssn << client[:id]
        end
        if client[:dob].blank? || missing?(client[:dob_data_quality])
          missing_dob << client[:id]
        end
        if client[:veteran_status].blank? || missing?(client[:veteran_status])
          missing_veteran << client[:id]
        end
        if client[:ethnicity].blank? || missing?(client[:ethnicity])
          missing_ethnicity << client[:id]
        end
        # If we have no race info, whatsoever
        if missing?(client[:race_none]) && missing?(client[:am_ind_ak_native]) && missing?(client[:asian]) && missing?(client[:black_af_american]) && missing?(client[:native_hi_other_pacific]) && missing?(client[:white])
          missing_race << client[:id]
        end
        if client[:gender].blank? || missing?(client[:gender])
          missing_gender << client[:id]
        end

        if client[:first_name].blank? || client[:last_name].blank? || refused?(client[:name_data_quality])
          refused_name << client[:id]
        end
        if client[:ssn].blank? || refused?(client[:ssn_data_quality])
          refused_ssn << client[:id]
        end
        if client[:dob].blank? || refused?(client[:dob_data_quality])
          refused_dob << client[:id]
        end
        if client[:veteran_status].blank? || refused?(client[:veteran_status])
          refused_veteran << client[:id]
        end
        if client[:ethnicity].blank? || refused?(client[:ethnicity])
          refused_ethnicity << client[:id]
        end
        if refused?(client[:race_none])
          refused_race << client[:id]
        end
        if client[:gender].blank? || refused?(client[:gender])
          refused_gender << client[:id]
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

      add_answers({
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
        
      })
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
      meets_dq_benchmark = report.with_indifferent_access.values_at(*percentages).values.max < MISSING_THRESHOLD rescue false
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
          missing_disabling_condition << client_id if missing?(enrollment[:disabling_condition])
          missing_prior_living << client_id if missing?(enrollment[:residence_prior])
          refused_disabling_condition << client_id if refused?(enrollment[:disabling_condition])
          refused_prior_living << client_id if refused?(enrollment[:residence_prior])
        end
      end
      leavers.each do |client_id|
        enrollments[client_id].each do |enrollment|
          missing_destination << client_id if missing?(enrollment[:destination])
          refused_destination << client_id if refused?(enrollment[:destination])
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

      add_answers({
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
      })
    end

    def add_length_of_stay
      client_count = clients.size
      one_year_enrollments = Set.new
      enrollments.each do |client_id, enrollments|
        months_in_project = 0
        enrollments.each do |enrollment|
          end_of_enrollment = enrollment[:last_date_in_program] || self.end
          months_in_project += (end_of_enrollment - enrollment[:first_date_in_program]).to_i/12
        end
        one_year_enrollments << client_id if months_in_project < 12
      end
      one_year_enrollments_percentage = (one_year_enrollments.size.to_f/client_count*100).round(2) rescue 0
      add_answers({
        one_year_enrollments: one_year_enrollments.size,
        one_year_enrollments_percentage: one_year_enrollments_percentage,
      })
    end

    def destination_ph
      ph_destinations = Set.new
      ph_project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
      leavers.each do |client_id|
        enrollments[client_id].each do |enrollment|
          ph_destinations << client_id if ph_project_types.include?(enrollment[:destination])
        end
      end
      ph_destinations_percentage = ph_destinations.size/leavers.size*100 rescue 0
      add_answers({
        ph_destinations: ph_destinations.size,
        ph_destinations_percentage: ph_destinations_percentage,
      })
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
        increased_earned << client_id if last_earned_income > first_earned_income
        increased_non_cash << client_id if last_non_cash_income > first_non_cash_income
        increased_overall << client_id if last_total_income > first_total_income
      end

      increased_earned_percentage = (increased_earned.to_f/clients.size*100).round(2) rescue 0
      increased_non_cash_percentage = (increased_non_cash.to_f/clients.size*100).round(2) rescue 0
      increased_overall_percentage = (increased_overall.to_f/clients.size*100).round(2) rescue 0
      add_answers({
        increased_earned: increased_earned.size,
        increased_non_cash: increased_non_cash.size,
        increased_overall: increased_overall.size,
        increased_earned_percentage: increased_earned_percentage,
        increased_non_cash_percentage: increased_non_cash_percentage,
        increased_overall_percentage: increased_overall_percentage,
      })

    end

    def add_capacity_answers
      total_services_provided = service_scope.select(:client_id, :date).distinct.to_a.count
      days_served = (self.end - self.start).to_i
      average_usage = (total_services_provided.to_f/days_served).round(2)
      capacity = (average_usage.to_f/beds*100).round(2) rescue 0
      add_answers({
        services_provided: total_services_provided,
        days_of_service: days_served,
        average_daily_usage: average_usage,
        capacity_percentage: capacity,
      })
    end


  end
end