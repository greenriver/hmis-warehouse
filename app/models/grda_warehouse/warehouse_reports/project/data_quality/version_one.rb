module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionOne < Base
    MISSING_THRESHOLD = 10
    def run!
      start_report()
      set_project_metadata()
      set_bed_coverage_data()
      calculate_missing_universal_elements()
      add_agency_entering_data()
      add_length_of_stay()
      destination_ph()
      add_income_answers()
      add_capacity_answers()
      finish_report()
    end

    def report_columns
      {
        total_clients: 'Clients included',
        agency_name: 'Agency name',
        project_name: 'Project name',
        monitoring_date_range: 'Operating year (Funder start date and end date)',
        monitoring_date_range_present: 'Operating year present?',
        grant_id: 'Grant identification #',
        coc_program_component: 'CoC program component (project type)',
        target_population: 'Target population',
        entering_required_data: 'Is the agency entering the required data/descriptor touch-points into HMIS for this project?',
        bed_coverage: 'Bed coverage',
        bed_coverage_percent: 'Bed coverage percent',
        missing_name_percent: 'Missing names in %',
        missing_ssn_percent: 'Missing SSN in %',
        missing_dob_percent: 'Missing DOB in %',
        missing_veteran_percent: 'Missing veteran status in %',
        missing_ethnicity_percent: 'Missing ethnicity in %',
        missing_race_percent: 'Missing race in %',
        missing_gender_percent: 'Missing gender in %',
        refused_name_percent: 'Refused name in %',
        refused_ssn_percent: 'Refused SSN in %',
        refused_dob_percent: 'Refused DOB in %',
        refused_veteran_percent: 'Refused veteran status in %',
        refused_ethnicity_percent: 'Refused ethnicity in %',
        refused_race_percent: 'Refused race in %',
        refused_gender_percent: 'Refused gender in %',
        one_year_enrollments: 'Enrollments lasting 12 or more months',
        one_year_enrollments_percentage: 'clients with enrollments lasting 12 or more months in %',
        ph_destinations_percentage: 'leavers who exited to PH in %',
        increased_earned: 'Clients with increased earned income',
        increased_earned_percentage: 'Percentage of clients who had increased earned income',
        increased_non_cash: 'Clients with increased non-cash income',
        increased_non_cash_percentage: 'Percentage of clients who had increased non-cash income',
        increased_overall: 'Clients with increased overall income',
        increased_overall_percentage: 'Percentage of clients who had increased total income',
        services_provided: 'Number of service events',
        days_of_service: 'Number of days in selected range',
        average_daily_usage: 'Average daily usage',
        capacity_percentage: 'Percentage of beds in use, on average',
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
        if missing?(client[:race_none])
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

      percentages = {
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

      meets_dq_benchmark = percentages.values.max < MISSING_THRESHOLD rescue false
      add_answers({
        total_clients: clients.size,
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
        meets_dq_benchmark: meets_dq_benchmark
      })
      add_answers(percentages)
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

      increased_earned_percentage = (increased_earned.to_f/incomes.size*100).round(2) rescue 0
      increased_non_cash_percentage = (increased_non_cash.to_f/incomes.size*100).round(2) rescue 0
      increased_overall_percentage = (increased_overall.to_f/incomes.size*100).round(2) rescue 0
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
      total_services_provided = service_scope.count
      days_served = (self.end - self.start).to_i
      average_usage = total_services_provided.to_f/days_served
      capacity = average_usage.to_f/beds*100 rescue 0
      add_answers({
        services_provided: total_services_provided,
        days_of_service: days_served,
        average_daily_usage: average_usage,
        capacity_percentage: capacity,
      })
    end


  end
end