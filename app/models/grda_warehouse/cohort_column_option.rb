module GrdaWarehouse
  class CohortColumnOption < GrdaWarehouseBase
    validates_presence_of :cohort_column, :value
    
    def cohort_columns 
      @cohort_columns ||= [
        ::CohortColumns::HousingSearchAgency.new(),
        ::CohortColumns::HousingOpportunity.new(),
        ::CohortColumns::LegalBarriers.new(),
        ::CohortColumns::DocumentReady.new(),
        ::CohortColumns::SensoryImpaired.new(),
        ::CohortColumns::Destination.new(),
        ::CohortColumns::SubPopulation.new(),
        ::CohortColumns::StFrancisHouse.new(),
        ::CohortColumns::HousingTrackSuggested.new(),
        ::CohortColumns::PrimaryHousingTrackSuggested.new(),
        ::CohortColumns::HousingTrackEnrolled.new(),
        ::CohortColumns::VaEligible.new(),
        ::CohortColumns::Chapter115.new(),
        ::CohortColumns::LocationType.new(),
        ::CohortColumns::Location.new(),
        ::CohortColumns::Status.new(),
        ::CohortColumns::NotAVet.new(),
        ::CohortColumns::CriminalRecordStatus.new(),
        ::CohortColumns::NewLeaseReferral.new(),
      ]
    end
    
    def available_cohort_columns
      cohort_columns.map{|c| [c.title, c.column]}.sort_by(&:first).to_h
    end

  end
end
