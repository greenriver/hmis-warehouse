module PitPopulations
  extend ActiveSupport::Concern
  POPULATIONS = {
    homeless: {
      family: {
        total_number_of_households: {}, 
        number_of_children: {}, 
        number_of_youth: {},
        number_of_adults: {},
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }, 
      children: {
        total_number_of_households: {}, 
        number_of_children: {}, 
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }, 
      adults:{
        total_number_of_households: {}, 
        number_of_youth: {},
        number_of_adults: {},
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }
    },
    homeless_sub: {
      homeless_subpopulations: {
        chronically_homeless_individuals: {},
        chronically_homeless_families: {},
        persons_in_chronically_homeless_familes: {},
        chronically_homeless_veteran_individuals: {},
        chronically_homeless_veteran_families: {},
        persons_in_chronically_homeless_veteran_familes: {},
        adults_with_serious_mental_illness: {},
        adults_with_serious_mental_illness_indefinite_and_impairs: {},
        adults_with_substance_use_disorder: {},
        adults_with_substance_use_disorder_indefinite_and_impairs: {},
        'adults with HIV/AIDS' => {},
        'adults with HIV/AIDS indefinite and impairs' => {},
        victims_of_domestic_violence: {},
        victims_of_domestic_violence_currently_fleeing: {},
      }
    },
    youth: {
      unaccompanied_youth: {
        total_number_of_households: {}, 
        number_of_children: {}, 
        number_of_youth: {},
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }, 
      youth_family: {
        total_number_of_households: {}, 
        number_of_parenting_children: {}, 
        number_of_parenting_youth: {},
        number_of_children: {},
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }
    }, 
    veteran: {
      veteran_family: {
        total_number_of_households: {}, 
        number_of_persons: {}, 
        number_of_veterans: {},
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }, 
      veteran_adults: {
        total_number_of_households: {}, 
        number_of_persons: {}, 
        number_of_veterans: {},
        female: {},
        male: {},
        transgender: {},
        gender_non_conforming: {},
        'non-hispanic/non-latino' => {},
        'hispanic/latino' => {},
        white: {},
        'black or african-american' => {},
        asian: {},
        american_indian_or_alaska_native: {},
        native_hawaiian_or_other_pacific_islander: {},
        multiple_races: {},
      }
    },
  }

  HOMELESS_BREAKDOWNS = [:es, :th, :so]
  HOMELESS_ADULT_BREAKDOWNS = [:es, :th, :sh, :so]
  HOMELESS_SUB_BREAKDOWNS = [:es, :sh, :so]
  UNACCOMPANIED_YOUTH_BREAKDOWNS = [:es, :th, :sh, :so]
  PARENTING_YOUTH_BREAKDOWNS = [:es, :th, :so]
  VETERAN_FAMILY_BREAKDOWNS = [:es, :th, :so]
  VETERAN_ADULT_BREAKDOWNS = [:es, :th, :sh, :so]
  included do
    def setup_answers
      @answers = POPULATIONS.deep_dup
      @answers[:homeless][:family].each do |q, breakdowns|
        breakdowns.merge!(HOMELESS_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers[:homeless][:children].each do |q, breakdowns|
        breakdowns.merge!(HOMELESS_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers[:homeless][:adults].each do |q, breakdowns|
        breakdowns.merge!(HOMELESS_ADULT_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers[:homeless_sub].each do |tab, questions|
        questions.each do |q, breakdowns|
          breakdowns.merge!(HOMELESS_SUB_BREAKDOWNS.map{|m| [m, 0]}.to_h)
        end
      end
      @answers[:youth][:youth_family].each do |q, breakdowns|
        breakdowns.merge!(PARENTING_YOUTH_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers[:youth][:unaccompanied_youth].each do |q, breakdowns|
        breakdowns.merge!(UNACCOMPANIED_YOUTH_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers[:veteran][:veteran_family].each do |q, breakdowns|
        breakdowns.merge!(VETERAN_FAMILY_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers[:veteran][:veteran_adults].each do |q, breakdowns|
        breakdowns.merge!(VETERAN_ADULT_BREAKDOWNS.map{|m| [m, 0]}.to_h)
      end
      @answers
    end
  end
end