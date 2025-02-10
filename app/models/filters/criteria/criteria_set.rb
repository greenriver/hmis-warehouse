# enumerable wrapper for criteria set
#
class Filters::Criteria::CriteriaSet
  include Enumerable

  def initialize(criteria)
    @criteria = Array(criteria)
  end

  def each(&block)
    @criteria.each(&block)
  end

  # Returns a new CriteriaSet with filtered criteria (this is array filter)
  def filter(&block)
    CriteriaSet.new(@criteria.filter(&block))
  end

  # Class method to apply criteria to an arel scope
  def apply(scope)
    reduce(scope) do |result, criterion|
      criterion.apply(result)
    end
  end

  CRITERIA_CLASS_NAMES = [
    # project
    'Filters::Criteria::FilterForUserAccess',
    'Filters::Criteria::FilterForRange',
    'Filters::Criteria::FilterForCocs',
    'Filters::Criteria::FilterForProjectType',
    'Filters::Criteria::FilterForProjects',
    'Filters::Criteria::FilterForFunders',
    'Filters::Criteria::FilterForDataSources',
    'Filters::Criteria::FilterForOrganizations',

    # client
    'Filters::Criteria::FilterForHouseholdType',
    'Filters::Criteria::FilterForHeadOfHousehold',
    'Filters::Criteria::FilterForAge',
    'Filters::Criteria::FilterForGender',
    'Filters::Criteria::FilterForRace',
    'Filters::Criteria::FilterForVeteranStatus',
    'Filters::Criteria::FilterForSubPopulation',
    'Filters::Criteria::FilterForPriorLivingSituation',
    'Filters::Criteria::FilterForDestination',
    'Filters::Criteria::FilterForDisabilities',
    'Filters::Criteria::FilterForIndefiniteDisabilities',
    'Filters::Criteria::FilterForDvStatus',
    'Filters::Criteria::FilterForDvCurrentlyFleeing',
    'Filters::Criteria::FilterForChronicAtEntry',
    'Filters::Criteria::FilterForChronicStatus',
    'Filters::Criteria::FilterForRrhMoveIn',
    'Filters::Criteria::FilterForPshMoveIn'
    'Filters::Criteria::FilterForFirstTimeHomelessInPastTwoYears',
    'Filters::Criteria::FilterForReturnedToHomelessnessFromPermanentDestination',
    'Filters::Criteria::FilterForCaHomeless',
    'Filters::Criteria::FilterForCeClsHomeless',
    'Filters::Criteria::FilterForCohorts',
    'Filters::Criteria::FilterForActiveRoi',
    'Filters::Criteria::FilterForTimesHomeless',
    'Filters::Criteria::FilterForDaysSinceContact',
    'Filters::Criteria::FilterForDaysSinceContact',
  ].freeze
end
