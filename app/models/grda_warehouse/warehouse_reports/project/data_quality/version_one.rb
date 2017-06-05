module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionOne < Base
    
    def run!
      start_report()
      set_project_metadata()
      set_bed_coverage_data()
      calculate_missing_universal_elements()
      finish_report()
    end


    def set_project_metadata
      funder = project.funders.last
      add_answers({
        agency_name: project.organization.OrganizationName,
        project_name: project.ProjectName,
        monitoring_date_range: "#{self.start} - #{self.end}",
        funding_year: funder.operating_year,
        grant_id: funder.GrantID,
        coc_program_component: ::HUD.project_type(project.ProjectType),
        target_population: ::HUD.target_population(project.TargetPopulation) || '',
      })
    end

    def set_bed_coverage_data
      beds = project.inventories.map(&:BedInventory).reduce(:+) || 0
      hmis_beds = project.inventories.map(&:HMISParticipatingBeds).reduce(:+) || 0
      
      bed_coveage = 0 
      bed_coveage_percent = 0
      if hmis_beds > 0
        bed_coveage = "#{beds} / #{hmis_beds}"
        bed_coverage_percent = beds/hmis_beds*100
      end
      add_answers({
        bed_coverage: bed_coveage,
        bed_coverage_percent: bed_coverage_percent,
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

      missing_name_percent = missing_name.size/clients.size*100 rescue 0
      missing_ssn_percent = missing_ssn.size/clients.size*100 rescue 0
      missing_dob_percent = missing_dob.size/clients.size*100 rescue 0
      missing_veteran_percent = missing_veteran.size/clients.size*100 rescue 0
      missing_ethnicity_percent = missing_ethnicity.size/clients.size*100 rescue 0
      missing_race_percent = missing_race.size/clients.size*100 rescue 0
      missing_gender_percent = missing_gender.size/clients.size*100 rescue 0
      refused_name_percent = refused_name.size/clients.size*100 rescue 0
      refused_ssn_percent = refused_ssn.size/clients.size*100 rescue 0
      refused_dob_percent = refused_dob.size/clients.size*100 rescue 0
      refused_veteran_percent = refused_veteran.size/clients.size*100 rescue 0
      refused_ethnicity_percent = refused_ethnicity.size/clients.size*100 rescue 0
      refused_race_percent = refused_race.size/clients.size*100 rescue 0
      refused_gender_percent = refused_gender.size/clients.size*100 rescue 0

      add_answers({
        total_clients: clients.size,
        missing_name: missing_name.size,
        missing_name_percent: missing_name_percent,
        missing_ssn: missing_ssn.size,
        missing_ssn_percent: missing_ssn_percent,
        missing_dob: missing_dob.size,
        missing_dob_percent: missing_dob_percent,
        missing_veteran: missing_veteran.size,
        missing_veteran_percent: missing_veteran_percent,
        missing_ethnicity: missing_ethnicity.size,
        missing_ethnicity_percent: missing_ethnicity_percent,
        missing_race: missing_race.size,
        missing_race_percent: missing_race_percent,
        missing_gender: missing_gender.size,
        missing_gender_percent: missing_gender_percent,
        refused_name: refused_name.size,
        refused_name_percent: refused_name_percent,
        refused_ssn: refused_ssn.size,
        refused_ssn_percent: refused_ssn_percent,
        refused_dob: refused_dob.size,
        refused_dob_percent: refused_dob_percent,
        refused_veteran: refused_veteran.size,
        refused_veteran_percent: refused_veteran_percent,
        refused_ethnicity: refused_ethnicity.size,
        refused_ethnicity_percent: refused_ethnicity_percent,
        refused_race: refused_race.size,
        refused_race_percent: refused_race_percent,
        refused_gender: refused_gender.size,
        refused_gender_percent: refused_gender_percent,

      })
    end


  end
end