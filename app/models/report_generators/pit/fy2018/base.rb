###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# https://www.hudexchange.info/resources/documents/Notice-CPD-16-060-2017-HIC-PIT-Data-Collection-Notice.pdf
#
# https://www.hudexchange.info/resources/documents/2016-HIC-PIT-Combined-Data-Submission-Guidance.pdf
#
#
# HIC Notes:
# *Sheltered Person Counts on the HIC and PIT Must Be Equal*
#
# Project Types (HIC):
#   ES, TH, SH, PH (PSH, RRH, Other PH (OPH) – consists of PH – Housing with Services (no disability required for entry) and PH – Housing Only)
#   OR numerically
#   1, 2, 3, 8, 9, 10, 13
#
# Items needed in HIC, not included in HMIS data
# * Victim Services Provider
# * Target Population A
#
# Inventory with a future "Inventory start date" should be considered (U) Under development
#
# PIT Notes
#   CoCs should report on people based on where they are sleeping on the night of the count, as opposed to the program they are enrolled in.
#    RRH + PH (don't count)
#    RRH + ES/SO/TH/SH - do count
#
# Count includes sheltered and unsheltered count
#   Count sheltered individuals who entered on or before the count date who exited after the count date (or not at all)
#   Unsheltered may be counted on the day of or day after the count
#
# Youth breakdown - no one > 24
# Parenting youth - subset of households with children if parent >= 18 <= 24 with children,
#   or subset of children only if parent < 18
# Unaccompanied youth - individual < 25 counted as a subset of households with only children if < 18, households without children if >= 18 <= 24
#
# Project Types (PIT):
#
module ReportGenerators::Pit::Fy2018
  class Base
    PROJECT_TYPES = {
      th: [2],
      es: [1],
      sh: [8],
      so: [4],
    }
    # We'll remove anyone who is also in PH, but
    # don't remove RRH (13), but don't explicitly include it.
    REMOVE_PROJECT_TYPES = [3, 9, 10]

    ADULT = 24
    YOUTH = 18

    include PitPopulations
    include ArelHelper

    def report_class
      Reports::Pit::Fy2018::Base
    end

    def initialize options
      @pit_date = options[:pit_date]
      @chronic_date = options[:chronic_date]
      @coc_codes = options.try(:[], :coc_codes)
      @user = User.find(options[:user_id].to_i)
      if @coc_codes.blank?
        @coc_codes = GrdaWarehouse::Hud::ProjectCoc.viewable_by(@user).
          distinct.pluck(:CoCCode)
      end
    end

    def run!
      # Find the first queued report
      report = ReportResult.where(report: report_class.first).where(percent_complete: 0).first
      raise "Report not found #{report_class.first.name}" unless report.present?
      Rails.logger.info "Starting report #{report.report.name}"
      report.update(percent_complete: 0.01)
      @answers = setup_answers
      @support = @answers.deep_dup
      answer_methods = [
        :add_homeless_family_answers,
        :add_homeless_children_answers,
        :add_homeless_adults_answers,
        :add_chronic_answers,
        :add_homeless_sub_population_answers,
        :add_unaccompanied_youth_answers,
        :add_youth_family_answers,
        :add_veteran_family_answers,
        :add_veteran_adult_answers,
      ]

      answer_methods.each_with_index do |method, i|
        percent = ((i/answer_methods.size.to_f)* 100)
        percent = 0.01 if percent == 0
        Rails.logger.info "Starting #{method}, #{percent.round(2)}% complete"
        report.update(percent_complete: percent)
        GC.start

        # Rails.logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
        self.send(method)
        Rails.logger.info "Completed #{method}"
      end

      report.update(percent_complete: 100, results: @answers, original_results: @answers, validations: @validations, support: @support, completed_at: Time.now)
      Rails.logger.info "Completed report #{report.report.name}"
      return @answers
    end

    def add_homeless_family_answers
      add_homeless_answers(section: :homeless, household_type: :family, breakdown: HOMELESS_BREAKDOWNS)
    end

    def add_homeless_children_answers
      add_homeless_answers(section: :homeless, household_type: :children, breakdown: HOMELESS_BREAKDOWNS)
    end

    def add_homeless_adults_answers
      add_homeless_answers(section: :homeless, household_type: :adults, breakdown: HOMELESS_ADULT_BREAKDOWNS)
    end

    def add_unaccompanied_youth_answers
      add_homeless_answers(section: :youth, household_type: :unaccompanied_youth, breakdown: UNACCOMPANIED_YOUTH_BREAKDOWNS)
    end

    def add_youth_family_answers
      add_homeless_answers(section: :youth, household_type: :youth_family, breakdown: PARENTING_YOUTH_BREAKDOWNS)
    end

    def add_veteran_family_answers
      add_homeless_answers(section: :veteran, household_type: :veteran_family, breakdown: VETERAN_FAMILY_BREAKDOWNS)
    end

    def add_veteran_adult_answers
      add_homeless_answers(section: :veteran, household_type: :veteran_adults, breakdown: VETERAN_ADULT_BREAKDOWNS)
    end

    def add_homeless_sub_population_answers
      unsheltered_adults = involved_clients.values.flatten.select do |enrollment|
        PROJECT_TYPES[:so].include?(enrollment[:project_type]) && is_adult?(age: enrollment[:age])
      end.map{|m| m[:client_id]}
      th_adults = involved_clients.values.flatten.select do |enrollment|
        PROJECT_TYPES[:th].include?(enrollment[:project_type]) && is_adult?(age: enrollment[:age])
      end.map{|m| m[:client_id]}
      sh_adults = involved_clients.values.flatten.select do |enrollment|
        PROJECT_TYPES[:sh].include?(enrollment[:project_type]) && is_adult?(age: enrollment[:age])
      end.map{|m| m[:client_id]}
      es_adults = involved_clients.values.flatten.select do |enrollment|
        PROJECT_TYPES[:es].include?(enrollment[:project_type]) && is_adult?(age: enrollment[:age])
      end.map{|m| m[:client_id]}


      sheltered_adults = (th_adults + es_adults).uniq

      {es: es_adults, th: th_adults, sh: sh_adults, so: unsheltered_adults}.each do |k, population|
        # Build an actual client object because we need to run down some relationships
        mental_illness_clients = []
        mental_illness_clients_indefinite_and_impairs = []
        substance_use_clients = []
        substance_use_clients_indefinite_and_impairs = []
        aids_clients = []
        aids_clients_indefinite_and_impairs = []
        dv_clients = []
        dv_clients_currently_fleeing_clients = []

        population.each do |id|
          mental_illness = false
          mental_illness_indefinite_and_impairs = false
          substance_use = false
          substance_use_indefinite_and_impairs = false
          aids = false
          aids_indefinite_and_impairs = false
          dv = false
          dv_currently_fleeing = false
          disabilities_for(client_id: id).each do |d|
            mental_illness = true if d[:DisabilityType] == 9 && d[:DisabilityResponse] == 1
            mental_illness_indefinite_and_impairs = true if d[:DisabilityType] == 9 && d[:DisabilityResponse] == 1 && d[:IndefiniteAndImpairs] == 1
            substance_use = true if d[:DisabilityType] == 10 && [1,2,3].include?(d[:DisabilityResponse])
            substance_use_indefinite_and_impairs = true if d[:DisabilityType] == 10 && [1,2,3].include?(d[:DisabilityResponse]) && d[:IndefiniteAndImpairs] == 1
            aids = true if d[:DisabilityType] == 8 && d[:DisabilityResponse] == 1
            aids_indefinite_and_impairs = true if d[:DisabilityType] == 8 && d[:DisabilityResponse] == 1 && d[:IndefiniteAndImpairs] == 1
          end
          health_for(client_id: id).each do |d|
            dv = true if d[:DomesticViolenceVictim] == 1
            dv_currently_fleeing = true if d[:DomesticViolenceVictim] == 1 && d[:CurrentlyFleeing] == 1
          end
          mental_illness_clients << id if mental_illness
          mental_illness_clients_indefinite_and_impairs << id if mental_illness_indefinite_and_impairs
          substance_use_clients << id if substance_use
          substance_use_clients_indefinite_and_impairs << id if substance_use_indefinite_and_impairs
          aids_clients << id if aids
          aids_clients_indefinite_and_impairs << id if aids_indefinite_and_impairs
          dv_clients << id if dv
          dv_clients_currently_fleeing_clients << id if dv_currently_fleeing
        end
        @answers[:homeless_sub][:homeless_subpopulations][:adults_with_serious_mental_illness][k] = mental_illness_clients.size
        @support[:homeless_sub][:homeless_subpopulations][:adults_with_serious_mental_illness][k] = {
          headers: ['Client ID'],
          counts: mental_illness_clients.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations][:adults_with_serious_mental_illness_indefinite_and_impairs][k] = mental_illness_clients_indefinite_and_impairs.size
        @support[:homeless_sub][:homeless_subpopulations][:adults_with_serious_mental_illness_indefinite_and_impairs][k] = {
          headers: ['Client ID'],
          counts: mental_illness_clients_indefinite_and_impairs.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations][:adults_with_substance_use_disorder][k] = substance_use_clients.size
        @support[:homeless_sub][:homeless_subpopulations][:adults_with_substance_use_disorder][k] = {
          headers: ['Client ID'],
          counts: substance_use_clients.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations][:adults_with_substance_use_disorder_indefinite_and_impairs][k] = substance_use_clients_indefinite_and_impairs.size
        @support[:homeless_sub][:homeless_subpopulations][:adults_with_substance_use_disorder_indefinite_and_impairs][k] = {
          headers: ['Client ID'],
          counts: substance_use_clients_indefinite_and_impairs.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations]['adults with HIV/AIDS'][k] = aids_clients.size
        @support[:homeless_sub][:homeless_subpopulations]['adults with HIV/AIDS'][k] = {
          headers: ['Client ID'],
          counts: aids_clients.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations]['adults with HIV/AIDS indefinite and impairs'][k] = aids_clients_indefinite_and_impairs.size
        @support[:homeless_sub][:homeless_subpopulations]['adults with HIV/AIDS indefinite and impairs'][k] = {
          headers: ['Client ID'],
          counts: aids_clients_indefinite_and_impairs.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations][:victims_of_domestic_violence][k] = dv_clients.size
        @support[:homeless_sub][:homeless_subpopulations][:victims_of_domestic_violence][k] = {
          headers: ['Client ID'],
          counts: dv_clients.map{|m| [m]}
        }
        @answers[:homeless_sub][:homeless_subpopulations][:victims_of_domestic_violence_currently_fleeing][k] = dv_clients_currently_fleeing_clients.size
        @support[:homeless_sub][:homeless_subpopulations][:victims_of_domestic_violence_currently_fleeing][k] = {
          headers: ['Client ID'],
          counts: dv_clients_currently_fleeing_clients.map{|m| [m]}
        }
      end
    end

    def add_chronic_answers
      HOMELESS_SUB_BREAKDOWNS.each do |k, _|
        family_households = filter_households_by_makeup(project_type: k, household_type: :family, households: households)
        clients_in_families = family_households.values.flatten.map{|m| m[:client_id]}
        chronic_in_project_type = chronic_client_ids & client_ids_in_project_type(project_type: k)
        chronic_clients_in_families = chronic_in_project_type & clients_in_families

        # All
        chronic_individuals = chronic_in_project_type - chronic_clients_in_families
        chronic_households = family_households.select do |_, members|
          chronic = false
          members.each do |m|
            chronic = true if chronic_client_ids.include?(m[:client_id])
          end
          chronic
        end

        # Children only
        child_only_households = filter_households_by_makeup(project_type: k, household_type: :children, households: households)
        child_clients = child_only_households.values.flatten.map{|m| m[:client_id]}
        chronic_child_individuals = chronic_individuals & child_clients

        # Individual Adults
        adult_only_households = filter_households_by_makeup(project_type: k, household_type: :adults, households: households)
        adult_clients = adult_only_households.values.flatten.map{|m| m[:client_id]}
        chronic_adult_individuals = chronic_individuals & adult_clients

        # Youth
        youth_households = filter_households_by_makeup(project_type: k, household_type: :youth, households: households)
        youth_clients = youth_households.values.flatten.map{|m| m[:client_id]}

        chronic_youth_individuals = chronic_individuals & youth_clients
        chronic_youth_in_families = chronic_clients_in_families & youth_clients
        chronic_youth_households = youth_households.select do |_, members|
          chronic = false
          members.each do |m|
            chronic = true if (chronic_youth_individuals + chronic_youth_in_families).include?(m[:client_id])
          end
          chronic
        end

        # Vets
        chronic_veteran_individuals = chronic_individuals & veteran_client_ids
        chronic_veterans_in_families = chronic_clients_in_families & veteran_client_ids
        veteran_chronic_housenolds = chronic_households.select do |_, members|
          veteran = false
          members.each do |m|
            veteran = true if veteran_client_ids.include?(m[:client_id])
          end
          veteran
        end

        # Family
        @answers[:homeless][:family][:chronically_homeless_persons][k] = chronic_clients_in_families.size
        @support[:homeless][:family][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_clients_in_families.map{|m| [m]}
        }
        @answers[:homeless][:family][:chronically_homeless_households][k] = chronic_households.size

        # Child only
        @answers[:homeless][:children][:chronically_homeless_persons][k] = chronic_child_individuals.size
        @support[:homeless][:children][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_child_individuals.map{|m| [m]}
        }

        # Individual Adult
        @answers[:homeless][:adults][:chronically_homeless_persons][k] = chronic_adult_individuals.size
        @support[:homeless][:adults][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_adult_individuals.map{|m| [m]}
        }

        # Unaccompanied Youth
        @answers[:youth][:unaccompanied_youth][:chronically_homeless_persons][k] = chronic_youth_individuals.size
        @support[:youth][:unaccompanied_youth][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_youth_individuals.map{|m| [m]}
        }

        # Parenting Youth
        @answers[:youth][:youth_family][:chronically_homeless_persons][k] = chronic_youth_in_families.size
        @support[:youth][:youth_family][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_youth_in_families.map{|m| [m]}
        }
        @answers[:youth][:youth_family][:chronically_homeless_households][k] = chronic_youth_households.size

        # Veterans - Adult only
        @answers[:veteran][:veteran_adults][:chronically_homeless_persons][k] = chronic_veteran_individuals.size
        @support[:veteran][:veteran_adults][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_veteran_individuals.map{|m| [m]}
        }

        # Veterans - Family
        @answers[:veteran][:veteran_family][:chronically_homeless_persons][k] = chronic_veterans_in_families.size
        @support[:veteran][:veteran_family][:chronically_homeless_persons][k] = {
          headers: ['Client ID'],
          counts: chronic_veterans_in_families.map{|m| [m]}
        }
        @answers[:veteran][:veteran_family][:chronically_homeless_households][k] = veteran_chronic_housenolds.size
      end
    end

    def add_homeless_answers section:, household_type:, breakdown:
      breakdown.each do |k, _|
        involved_households = filter_households_by_makeup(project_type: k, household_type: household_type, households: households)
        # get an array of client_ids involved
        client_ids = involved_households.values.flatten.map{|m| m[:client_id]}.uniq

        @answers[section][household_type][:total_number_of_households][k] = involved_households.size
        @support[section][household_type][:total_number_of_households][k] = {
          headers: ['Household Size', 'Client IDs'],
          counts: involved_households.map{|_,m| [m.size, m.map{|c| c[:client_id]}.join(', ')]}
        }

        # determine age makeup
        makeup = life_stage_makeup(households: involved_households)
        case household_type
        when :adults
          @answers[section][household_type][:number_of_adults][k] = makeup[:number_of_adults].size
          @support[section][household_type][:number_of_adults][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_adults].map{|m| [m]}
          }
          @answers[section][household_type][:number_of_youth][k] = makeup[:number_of_youth].size
          @support[section][household_type][:number_of_youth][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_youth].map{|m| [m]}
          }
        when :children
          @answers[section][household_type][:number_of_children][k] = makeup[:number_of_children].size
          @support[section][household_type][:number_of_children][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_children].map{|m| [m]}
          }
        when :family
          @answers[section][household_type][:number_of_adults][k] = makeup[:number_of_adults].size
          @support[section][household_type][:number_of_adults][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_adults].map{|m| [m]}
          }
          @answers[section][household_type][:number_of_children][k] = makeup[:number_of_children].size
          @support[section][household_type][:number_of_children][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_children].map{|m| [m]}
          }
          @answers[section][household_type][:number_of_youth][k] = makeup[:number_of_youth].size
          @support[section][household_type][:number_of_youth][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_youth].map{|m| [m]}
          }
        when :unaccompanied_youth
          @answers[section][household_type][:number_of_children][k] = makeup[:number_of_children].size
          @support[section][household_type][:number_of_children][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_children].map{|m| [m]}
          }
          @answers[section][household_type][:number_of_youth][k] = makeup[:number_of_youth].size
          @support[section][household_type][:number_of_youth][k] = {
            headers: ['Client ID'],
            counts: makeup[:number_of_youth].map{|m| [m]}
          }
        when :youth_family
          child_parents = head_of_households_who_are(life_stage: :child, households: involved_households)
          youth_parents = head_of_households_who_are(life_stage: :youth, households: involved_households)
          # since some children may be parents as well, subtract them from the child count
          @answers[section][household_type][:number_of_children][k] = (makeup[:number_of_children] - child_parents).size
          @support[section][household_type][:number_of_children][k] = {
            headers: ['Client ID'],
            counts: (makeup[:number_of_children] - child_parents).map{|m| [m]}
          }
          @answers[section][household_type][:number_of_parenting_children][k] = child_parents.size
          @support[section][household_type][:number_of_parenting_children][k] = {
            headers: ['Client ID'],
            counts: child_parents.map{|m| [m]}
          }
          @answers[section][household_type][:number_of_parenting_youth][k] = youth_parents.size
          @support[section][household_type][:number_of_parenting_youth][k] = {
            headers: ['Client ID'],
            counts: youth_parents.map{|m| [m]}
          }
          # Limit client details to youth only
          client_ids = youth_parents
        when :veteran_family, :veteran_adults
          @answers[section][household_type][:number_of_persons][k] = client_ids.size
          @support[section][household_type][:number_of_persons][k] = {
            headers: ['Client ID'],
            counts: client_ids.map{|m| [m]}
          }
          @answers[section][household_type][:number_of_veterans][k] = (veteran_client_ids & client_ids).size
          # limit client details to vets only
          client_ids = veteran_client_ids & client_ids
          @support[section][household_type][:number_of_veterans][k] = {
            headers: ['Client ID'],
            counts: client_ids.map{|m| [m]}
          }
        end

        # determine gender makeup
        makeup = gender_makeup(client_ids: client_ids)
        @answers[section][household_type][:female][k] = makeup[:female].size
        @answers[section][household_type][:male][k] = makeup[:male].size
        @answers[section][household_type][:transgender][k] = makeup[:transgender].size
        @answers[section][household_type][:gender_non_conforming][k] = makeup[:gender_non_conforming].size

        # determine ethnicity makeup
        makeup = ethnicity_makeup(client_ids: client_ids)
        @answers[section][household_type]['non-hispanic/non-latino'][k] = makeup['non-hispanic/non-latino'].size
        @answers[section][household_type]['hispanic/latino'][k] = makeup['hispanic/latino'].size

        # determine race makeup
        makeup = race_makeup(client_ids: client_ids)
        @answers[section][household_type][:white][k] = makeup[:white].size
        @answers[section][household_type]['black or african-american'][k] = makeup['black or african-american'].size
        @answers[section][household_type][:asian][k] = makeup[:asian].size
        @answers[section][household_type][:american_indian_or_alaska_native][k] = makeup[:american_indian_or_alaska_native].size
        @answers[section][household_type][:native_hawaiian_or_other_pacific_islander][k] = makeup[:native_hawaiian_or_other_pacific_islander].size
        @answers[section][household_type][:multiple_races][k] = makeup[:multiple_races].size
      end
    end

    def filter_households_by_makeup project_type:, household_type:, households:
      households.select do |_, members|
        child = false
        adult = false
        youth = false
        older_adult = false
        veteran = false
        members.each do |m|
          age = determine_age(client_id: m[:client_id], age: m[:age])
          if is_child?(age: age)
            child = true
          else
            adult = true
          end
          if is_youth?(age: age)
            youth = true
          end
          if is_older_adult?(age: age)
            older_adult = true
          end
          case household_type
          when :veteran_family, :veteran_adults
            veteran = true if veteran_client_ids.include?(m[:client_id])
          end
        end
        case household_type
        when :family
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && child && adult
        when :children
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && child && ! adult
        when :adults
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && ! child && adult
        when :unaccompanied_youth
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && ((youth && ! (child || older_adult)) || (child && ! adult))
        when :youth_family
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && youth && child && ! older_adult
        when :veteran_family
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && child && adult && veteran
        when :veteran_adults
          PROJECT_TYPES[project_type].include?(members.first[:project_type]) && ! child && adult && veteran
        end
      end
    end

    def head_of_households_who_are life_stage:, households:
      heads = []
      households.each do |_, members|
        members.each do |m|
          if m[:RelationshipToHoH] == 1
            case life_stage
            when :child
              heads << m[:client_id] if is_child?(age: m[:age])
            when :youth
              heads << m[:client_id] if is_youth?(age: m[:age])
            end
          end
        end
      end
      heads
    end

    def life_stage_makeup households:
      # sometimes people sneak into a household more than once, only count them once
      ids = Set.new
      makeup = {
        number_of_children: Set.new,
        number_of_adults: Set.new,
        number_of_youth: Set.new,
      }
      households.each do |_, members|
        members.each do |m|
          next if ids.include?(m[:client_id])
          age = determine_age(client_id: m[:client_id], age: m[:age])
          if is_child?(age: age)
            makeup[:number_of_children] << m[:client_id]
          elsif is_youth?(age: age)
            makeup[:number_of_youth] << m[:client_id]
          else
            makeup[:number_of_adults] << m[:client_id]
          end
          ids << m[:client_id]
        end
      end
      makeup
    end

    def gender_makeup client_ids:
      makeup = {
        female: Set.new,
        male: Set.new,
        transgender: Set.new,
        gender_non_conforming: Set.new,
      }
      client_ids.each do |id|
        gender_code = metadata_for_client(client_id: id)[:Gender]
        case gender_code
        when 0
          makeup[:female] << id
        when 1
          makeup[:male] << id
        when 2,3
          makeup[:transgender] << id
        when 4
          makeup[:gender_non_conforming] << id
        end
      end
      makeup
    end

    def ethnicity_makeup client_ids:
      makeup = {
        'non-hispanic/non-latino' => Set.new,
        'hispanic/latino' => Set.new,
      }
      client_ids.each do |id|
        ethnicity_code = metadata_for_client(client_id: id)[:Ethnicity]
        case ethnicity_code
        when 0
          makeup['non-hispanic/non-latino'] << id
        when 1
          makeup['hispanic/latino'] << id
        end
      end
      makeup
    end

    def race_makeup client_ids:
      makeup = {
        white: Set.new,
        'black or african-american' => Set.new,
        asian: Set.new,
        american_indian_or_alaska_native: Set.new,
        native_hawaiian_or_other_pacific_islander: Set.new,
        multiple_races: Set.new,
      }
      client_ids.each do |id|
        races = metadata_for_client(client_id: id).slice(
          :AmIndAKNative,
          :Asian,
          :BlackAfAmerican,
          :NativeHIOtherPacific,
          :White
        ).select{|k,v| v == 1}
        if races.size == 1
          case races.keys.first
          when :AmIndAKNative
            makeup[:american_indian_or_alaska_native] << id
          when :Asian
            makeup[:asian] << id
          when :BlackAfAmerican
            makeup['black or african-american'] << id
          when :NativeHIOtherPacific
            makeup[:native_hawaiian_or_other_pacific_islander] << id
          when :White
            makeup[:white] << id
          end
        else
          makeup[:multiple_races] << id
        end
      end
      makeup
    end

    def chronic_client_ids
      @chronic_ids ||= chronic_scope.pluck(:client_id) & involved_clients.keys
    end


    def veteran_client_ids
      @veteran_ids ||= begin
        client_metadata.values.flatten.
          select{|m| m[:VeteranStatus] == 1}.
          map{|m| m[:id]}.uniq
      end
    end

    # Since we are only looking at service on one day, group anyone
    # together who has the same household_id
    def households
      @households ||= begin
        involved_clients.values.flatten.each do |service|
          # fake a household id if we don't have one
          service[:household_id] = "hh_#{service[:client_id]}_#{service[:project_id]}" unless service[:household_id].present?
        end.
        group_by{|m| [m[:household_id], m[:data_source_id]]}
      end
    end

    # Fetch everyone in one of the project types involved
    def potential_candidates
      @potential_candidates ||= begin
        service_history_scope.
          select(*sh_cols.values).
          pluck(*sh_cols.values).
          map do |ar|
            sh_cols.keys.zip(ar).to_h
          end.
          group_by{|m| m[:client_id]}
      end
    end

    def is_youth? age:
      age.present? && age <= ADULT && age >= YOUTH
    end

    def is_child? age:
      age.present? && age < YOUTH
    end

    def is_adult? age:
      age.blank? || age >= YOUTH
    end

    def is_older_adult? age:
      age.blank? || age > ADULT
    end

    # A hash keyed on client_id of all services provided for clients
    # who are only in the project types included in the PIT
    def involved_clients
      @involved_clients ||= begin
        # remove anyone in PH
        cleaned = potential_candidates.delete_if do |_, enrollments|
          enrollments.select{|m| REMOVE_PROJECT_TYPES.include?(m[:project_type])}.any?
        end
        # remove any enrollments that aren't in the PIT Project Types
        cleaned.each do |_, enrollments|
          enrollments.delete_if{|m| ! PROJECT_TYPES.values.flatten.include?(m[:project_type])}
        end
        # remove anyone who no longer has enrollments
        cleaned.delete_if do |_, enrollments|
          enrollments.empty?
        end
        # Limit each client to only one enrollment in the following priority
        # ES > SH > TH > SO
        cleaned.each do |client_id, enrollments|
          if enrollments.size > 1
            es = enrollments.select{|m| PROJECT_TYPES[:es].include?(m[:project_type])}
            sh = enrollments.select{|m| PROJECT_TYPES[:sh].include?(m[:project_type])}
            th = enrollments.select{|m| PROJECT_TYPES[:th].include?(m[:project_type])}
            so = enrollments.select{|m| PROJECT_TYPES[:so].include?(m[:project_type])}
            if es.any?
              cleaned[client_id] = [es.first]
            elsif sh.any?
              cleaned[client_id] = [sh.first]
            elsif th.any?
              cleaned[client_id] = [th.first]
            elsif so.any?
              cleaned[client_id] = [so.first]
            end
          end
        end
        cleaned
      end
    end

    def client_ids_in_project_type project_type:
      involved_clients.values.flatten.select do |m|
        PROJECT_TYPES[project_type].include?(m[:project_type])
      end.map{|m| m[:client_id]}.uniq
    end

    def determine_age client_id:, age:
      return age if age.present?
      infer_age(client_id: client_id)
    end

    def infer_age client_id:
      first_entry_date = first_entry_date(client_id: client_id)
      return nil unless first_entry_date.present?
      if first_entry_date < Date.current - 18.years # happened over 18 years ago
        return ((Date.current - first_entry_date)/365).to_i
      end
      return nil
    end

    def metadata_for_client(client_id:)
      client_metadata[client_id]
    end

    def client_metadata
      @client_metadata ||= begin
        {}.tap do |m|
          involved_clients.keys.each_slice(5000) do |ids|
            m.merge!(
              GrdaWarehouse::Hud::Client.
              where(id: ids).
              pluck(*client_columns.values).
              map do |ar|
                client_columns.keys.zip(ar).to_h
              end.
              index_by{|m| m[:id]}
            )
          end
        end
      end
    end

    def disabilities_for client_id:
      disabilities[client_id] || []
    end

    def disabilities
      @disabilities ||= begin
        {}.tap do |m|
          involved_clients.keys.each_slice(5000) do |ids|
            m.merge!(
              GrdaWarehouse::Hud::Disability.
              joins(:destination_client).
              where(warehouse_clients: {destination_id: ids}).
              pluck(*disability_columns.values, :destination_id).
              map do |ar|
                (disability_columns.keys + [:client_id]).zip(ar).to_h
              end.
              group_by{|m| m[:client_id]}
            )
          end
        end
      end
      @disabilities
    end

    def health_for client_id:
      health[client_id] || []
    end

    def health
      @health ||= begin
        {}.tap do |m|
          involved_clients.keys.each_slice(5000) do |ids|
            m.merge!(
              GrdaWarehouse::Hud::HealthAndDv.
              joins(:destination_client).
              where(warehouse_clients: {destination_id: ids}).
              pluck(*health_columns.values, :destination_id).
              map do |ar|
                (health_columns.keys + [:client_id]).zip(ar).to_h
              end.
              group_by{|m| m[:client_id]}
            )
          end
        end
      end
    end

    def first_entry_date client_id:
      @first_entries ||= begin
        GrdaWarehouse::ServiceHistoryEnrollment.
          first_date.where(
            client_id: involved_clients.keys
          ).
          pluck(:client_id, :date).to_h
      end
      @first_entries[client_id]
    end

    def service_history_scope
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:service_history_services).
        where(
          shs_t[:date].eq(@pit_date).
          and(shs_t[:record_type].eq('service'))
        ).
        joins(project: :project_cocs).
        where(pc_t[:CoCCode].in(@coc_codes)).
        joins(:enrollment).
        distinct
    end

    def chronic_scope
      GrdaWarehouse::HudChronic.where(date: @chronic_date)
    end

    def sh_cols
      @sh_cols ||= {
        project_type: act_as_project_overlay,
        client_id: she_t[:client_id].as('client_id').to_sql,
        enrollment_group_id: she_t[:enrollment_group_id].as('enrollment_group_id').to_sql,
        age: shs_t[:age].as('age').to_sql,
        household_id: she_t[:household_id].as('household_id').to_sql,
        project_id: she_t[:project_id].as('project_id').to_sql,
        data_source_id: she_t[:data_source_id].as('data_source_id').to_sql,
        RelationshipToHoH: e_t[:RelationshipToHoH].as('RelationshipToHoH').to_sql,
        unaccompanied_youth: she_t[:unaccompanied_youth].as('unaccompanied_youth').to_sql,
        parenting_youth: she_t[:parenting_youth].as('parenting_youth').to_sql,
        parenting_juvenile: she_t[:parenting_juvenile].as('parenting_juvenile').to_sql,
        children_only: she_t[:children_only].as('children_only').to_sql,
      }
    end

    def act_as_project_overlay
      nf( 'COALESCE', [ p_t[:act_as_project_type], shs_t[:project_type] ] ).as('project_type').to_sql
    end

    def client_columns
      {
        PersonalID: c_t[:PersonalID].as('PersonalID').to_sql,
        data_source_id: c_t[:data_source_id].as('data_source_id').to_sql,
        Gender: c_t[:Gender].as('Gender').to_sql,
        VeteranStatus: c_t[:VeteranStatus].as('VeteranStatus').to_sql,
        Ethnicity: c_t[:Ethnicity].as('Ethnicity').to_sql,
        AmIndAKNative: c_t[:AmIndAKNative].as('AmIndAKNative').to_sql,
        Asian: c_t[:Asian].as('Asian').to_sql,
        BlackAfAmerican: c_t[:BlackAfAmerican].as('BlackAfAmerican').to_sql,
        NativeHIOtherPacific: c_t[:NativeHIOtherPacific].as('NativeHIOtherPacific').to_sql,
        White: c_t[:White].as('White').to_sql,
        RaceNone: c_t[:RaceNone].as('RaceNone').to_sql,
        id: c_t[:id].as('id').to_sql,
      }
    end

    def disability_columns
      {
        DisabilityType: d_t[:DisabilityType].as('DisabilityType').to_sql,
        DisabilityResponse: d_t[:DisabilityResponse].as('DisabilityResponse').to_sql,
        IndefiniteAndImpairs: d_t[:IndefiniteAndImpairs].as('IndefiniteAndImpairs').to_sql,
      }
    end

    def health_columns
      {
        DomesticViolenceVictim: hdv_t[:DomesticViolenceVictim].as('DomesticViolenceVictim').to_sql,
        CurrentlyFleeing: hdv_t[:CurrentlyFleeing].as('CurrentlyFleeing').to_sql,
      }
    end
  end
end