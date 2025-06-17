###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Cohorts
  class CohortColumn < GrdaWarehouseBase
    validates :class_name, presence: true, uniqueness: true

    scope :active, -> { where(active: true) }

    def activate
      update(active: true)
    end

    def deactivate
      update(active: false)
      remove_from_cohorts
    end

    def remove_from_cohorts
      GrdaWarehouse::Cohort.all.each do |cohort|
        cohort.update!(column_state: cohort.column_state.reject { |col| col.cohort_column.class_name == class_name })
      end
    end

    def self.maintain!
      existing_class_names = all.pluck(:class_name).to_set
      known_cohort_columns.each do |class_name|
        create!(class_name: class_name, active: true) unless existing_class_names.include?(class_name)
      end
    end

    def self.known_cohort_columns
      columns = [
        'CohortColumns::LastName',
        'CohortColumns::FirstName',
        'CohortColumns::Rank',
        'CohortColumns::Age',
        'CohortColumns::Dob',
        'CohortColumns::Gender',
        'CohortColumns::Ssn',
        'CohortColumns::ClientId',
        'CohortColumns::CalculatedDaysHomeless',
        'CohortColumns::AdjustedDaysHomeless',
        'CohortColumns::AdjustedDaysHomelessLastThreeYears',
        'CohortColumns::AdjustedDaysLiterallyHomelessLastThreeYears',
        'CohortColumns::DaysHomelessPlusOverrides',
        'CohortColumns::FirstDateHomeless',
        'CohortColumns::Chronic',
        'CohortColumns::Agency',
        'CohortColumns::CaseManager',
        'CohortColumns::HousingManager',
        'CohortColumns::HousingSearchAgency',
        'CohortColumns::HousingOpportunity',
        'CohortColumns::LegalBarriers',
        'CohortColumns::CriminalRecordStatus',
        'CohortColumns::DocumentReady',
        'CohortColumns::SifEligible',
        'CohortColumns::SensoryImpaired',
        'CohortColumns::HousedDate',
        'CohortColumns::Destination',
        'CohortColumns::SubPopulation',
        'CohortColumns::IndividualInMostRecentEnrollment',
        'CohortColumns::StFrancisHouse',
        'CohortColumns::LastGroupReviewDate',
        'CohortColumns::LastDateApproached',
        'CohortColumns::PreContemplativeLastDateApproached',
        'CohortColumns::HousingTrackSuggested',
        'CohortColumns::PrimaryHousingTrackSuggested',
        'CohortColumns::HousingTrackEnrolled',
        'CohortColumns::VaEligible',
        'CohortColumns::VashEligible',
        'CohortColumns::Chapter115',
        'CohortColumns::Veteran',
        'CohortColumns::ClientNotes',
        'CohortColumns::Notes',
        'CohortColumns::VispdatScore',
        'CohortColumns::VispdatPriorityScore',
        'CohortColumns::HousingNavigator',
        'CohortColumns::LocationType',
        'CohortColumns::Location',
        'CohortColumns::LastContactLocation',
        'CohortColumns::Status',
        'CohortColumns::SsvfEligible',
        'CohortColumns::VetSquaresConfirmed',
        'CohortColumns::MissingDocuments',
        'CohortColumns::Provider',
        'CohortColumns::NextStep',
        'CohortColumns::HousingPlan',
        'CohortColumns::DateDocumentReady',
        'CohortColumns::DaysHomelessLastThreeYears',
        'CohortColumns::DaysLiterallyHomelessLastThreeYears',
        'CohortColumns::ShelteredDaysHomelessLastThreeYears',
        'CohortColumns::UnshelteredDaysHomelessLastThreeYears',
        'CohortColumns::EnrolledHomelessShelter',
        'CohortColumns::EnrolledHomelessUnsheltered',
        'CohortColumns::EnrolledPermanentHousing',
        'CohortColumns::RelatedUsers',
        'CohortColumns::Active',
        'CohortColumns::LastHomelessVisit',
        'CohortColumns::OngoingEs',
        'CohortColumns::OngoingSo',
        'CohortColumns::OngoingSh',
        'CohortColumns::OngoingTh',
        'CohortColumns::OngoingRrh',
        'CohortColumns::OngoingPsh',
        'CohortColumns::OngoingSso',
        'CohortColumns::NewLeaseReferral',
        'CohortColumns::VulnerabilityRank',
        'CohortColumns::ActiveCohorts',
        'CohortColumns::DestinationFromHomelessness',
        'CohortColumns::HmisDestination',
        'CohortColumns::OpenEnrollments',
        'CohortColumns::Ineligible',
        'CohortColumns::ConsentConfirmed',
        'CohortColumns::DisabilityVerificationDate',
        'CohortColumns::AvailableForMatchingInCas',
        'CohortColumns::DaysSinceCasMatch',
        'CohortColumns::Sober',
        'CohortColumns::OriginalChronic',
        'CohortColumns::NotAVet',
        'CohortColumns::EtoCoordinatedEntryAssessmentScore',
        'CohortColumns::HouseholdMembers',
        'CohortColumns::MinimumBedroomSize',
        'CohortColumns::SpecialNeeds',
        'CohortColumns::RrhDesired',
        'CohortColumns::YouthRrhDesired',
        'CohortColumns::RrhAssessmentContactInfo',
        'CohortColumns::RrhSsvfEligible',
        'CohortColumns::Reported',
        'CohortColumns::Race',
        'CohortColumns::Ethnicity',
        'CohortColumns::Lgbtq',
        'CohortColumns::LgbtqFromHmis',
        'CohortColumns::SleepingLocation',
        'CohortColumns::ExitDestination',
        'CohortColumns::ActiveInCasMatch',
        'CohortColumns::SchoolDistrict',
        'CohortColumns::AssessmentScore',
        'CohortColumns::PathwaysV3AssessmentDate',
        'CohortColumns::TransferV3AssessmentDate',
        'CohortColumns::VispdatScoreManual',
        'CohortColumns::DaysOnCohort',
        'CohortColumns::CasVashEligible',
        'CohortColumns::DateAddedToCohort',
        'CohortColumns::PreviousRemovalReason',
        'CohortColumns::HealthPrioritized',
        'CohortColumns::MostRecentDateToStreet',
        'CohortColumns::DaysHomelessPathways',
        'CohortColumns::MostRecentClsSheltered',
        'CohortColumns::CeAssessmentDate',
        'CohortColumns::CeAssessmentName',
        'CohortColumns::CeAssessmentUser',
        'CohortColumns::SourceClientPersonalIds',
        'CohortColumns::MostRecentHouseholdType',
        'CohortColumns::MostRecentSelfReportMonthsHomeless',
        'CohortColumns::MostRecentPriorLivingSituation',
        'CohortColumns::MostRecentCls',
        'CohortColumns::VeteranStatusCalculated',
        'CohortColumns::MostRecentDisablingCondition',
      ]
      columns << (1..30).map { |i| "CohortColumns::UserString#{i}" }
      columns << (1..49).map { |i| "CohortColumns::UserBoolean#{i}" }
      columns << (1..30).map { |i| "CohortColumns::UserSelect#{i}" }
      columns << (1..30).map { |i| "CohortColumns::UserDate#{i}" }
      columns << (1..10).map { |i| "CohortColumns::UserNumeric#{i}" }
      columns.flatten
    end
  end
end
