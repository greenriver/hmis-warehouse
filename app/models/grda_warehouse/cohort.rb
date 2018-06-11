module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    acts_as_paranoid
    validates_presence_of :name
    validates :days_of_inactivity, numericality: { only_integer: true, allow_nil: true }
    validates :static_column_count, numericality: { only_integer: true}
    serialize :column_state, Array

    has_many :cohort_clients, dependent: :destroy
    has_many :clients, through: :cohort_clients, class_name: 'GrdaWarehouse::Hud::Client'
    has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::UserViewableEntity'

    attr_accessor :client_ids, :user_ids

    scope :active, -> do
      where(active_cohort: true)
    end
    scope :inactive, -> do
      where(active_cohort: false)
    end

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.can_edit_cohort_clients? || user.can_manage_cohorts?
        current_scope
      elsif user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts?
        joins(:user_viewable_entities).
          where(GrdaWarehouse::UserViewableEntity.table_name => {user_id: user.id})
      else
        none
      end
    end

    def _scope(inactive: nil)
      if inactive.present?
        cohort_clients
      else
        cohort_clients.where(active: true)
      end
    end

    def search_clients(page:, per:, inactive: nil, population: nil)
      @client_search_scope = if inactive.present?
        cohort_clients
      else
        cohort_clients.where(active: true)
      end
      scope = case population.to_sym
      when :housed
        @client_search_scope.where.not(housed_date: nil).where(ineligible: [nil, false])
      when :ineligible
        @client_search_scope.where(ineligible: true)
      when :active
        @client_search_scope.where(housed_date: nil, ineligible: [nil, false])
      when nil
        @client_search_scope.where(housed_date: nil, ineligible: [nil, false])
      else
        raise ArgumentError, 'unexpected value for population'
      end
      # clear caches
      @last_activity_by_client_id = nil

      @client_search_result = scope.order(id: :asc).page(page).per(per).preload(
        :cohort_client_notes, {
          client: :processed_service_history
        }
      )
    end

    private def needs_client_search
      raise 'call #search_clients first' unless @client_search_scope.present? && @client_search_result.present?
    end

    # should we show the housed option for the last `client_search`
    def show_housed
      needs_client_search
      @client_search_scope.where.not(housed_date: nil).where(ineligible: [nil, false]).exists?
    end

    # should we show the inactive option for the last `client_search`
    def show_inactive
      needs_client_search
      client_search_scope.where(ineligible: true).exists?
    end

    # full un-paginated scope for the last `client_search`
    def client_search_scope
      needs_client_search
      @client_search_scope
    end

    # paginated/preloaded scope for the last `client_search`
    def client_search_result
      needs_client_search
      @client_search_result
    end

    # lazy loaded index of last_activity for the last `client_search`
    def last_activity_by_client_id
      @last_activity_by_client_id ||= begin
        GrdaWarehouse::ServiceHistoryService.homeless.where(
          client_id: client_search_result.map(&:id)
        ).group(:client_id).maximum(:date).to_h
      end
    end

    def self.has_some_cohort_access user
      user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts? || user.can_edit_cohort_clients? || user.can_manage_cohorts?
    end

    def user_can_edit_cohort_clients user
      user.can_manage_cohorts? || user.can_edit_cohort_clients? || (user.can_edit_assigned_cohorts? && user.cohorts.where(id: id).exists?)
    end

    def update_access user_ids
      GrdaWarehouse::UserViewableEntity.transaction do
        entity_type = self.class.name
        GrdaWarehouse::UserViewableEntity.where(entity_type: entity_type, entity_id: id).where.not(user_id: user_ids).destroy_all
        user_ids.each do |user_id|
          GrdaWarehouse::UserViewableEntity.where(entity_type: entity_type, entity_id: id, user_id: user_id).first_or_create
        end
      end

    end

    def inactive?
      !active_cohort?
    end

    def visible_columns
      return self.class.default_visible_columns unless column_state.present?
      column_state&.select(&:visible)&.presence || self.class.available_columns
    end

    def self.default_visible_columns
      [
        ::CohortColumns::LastName.new(),
        ::CohortColumns::FirstName.new(),
      ]
    end

    def self.available_columns
      [
        ::CohortColumns::LastName.new(),
        ::CohortColumns::FirstName.new(),
        ::CohortColumns::Rank.new(),
        ::CohortColumns::Age.new(),
        ::CohortColumns::Gender.new(),
        ::CohortColumns::CalculatedDaysHomeless.new(),
        ::CohortColumns::AdjustedDaysHomeless.new(),
        ::CohortColumns::AdjustedDaysHomelessLastThreeYears.new(),
        ::CohortColumns::AdjustedDaysLiterallyHomelessLastThreeYears.new(),
        ::CohortColumns::FirstDateHomeless.new(),
        ::CohortColumns::Chronic.new(),
        ::CohortColumns::Agency.new(),
        ::CohortColumns::CaseManager.new(),
        ::CohortColumns::HousingManager.new(),
        ::CohortColumns::HousingSearchAgency.new(),
        ::CohortColumns::HousingOpportunity.new(),
        ::CohortColumns::LegalBarriers.new(),
        ::CohortColumns::CriminalRecordStatus.new(),
        ::CohortColumns::DocumentReady.new(),
        ::CohortColumns::SifEligible.new(),
        ::CohortColumns::SensoryImpaired.new(),
        ::CohortColumns::HousedDate.new(),
        ::CohortColumns::Destination.new(),
        ::CohortColumns::SubPopulation.new(),
        ::CohortColumns::StFrancisHouse.new(),
        ::CohortColumns::LastGroupReviewDate.new(),
        ::CohortColumns::LastDateApproached.new(),
        ::CohortColumns::PreContemplativeLastDateApproached.new(),
        ::CohortColumns::HousingTrackSuggested.new(),
        ::CohortColumns::PrimaryHousingTrackSuggested.new(),
        ::CohortColumns::HousingTrackEnrolled.new(),
        ::CohortColumns::VaEligible.new(),
        ::CohortColumns::VashEligible.new(),
        ::CohortColumns::Chapter115.new(),
        ::CohortColumns::Veteran.new(),
        ::CohortColumns::Notes.new(),
        ::CohortColumns::VispdatScore.new(),
        ::CohortColumns::VispdatPriorityScore.new(),
        ::CohortColumns::HousingNavigator.new(),
        ::CohortColumns::LocationType.new(),
        ::CohortColumns::Location.new(),
        ::CohortColumns::Status.new(),
        ::CohortColumns::SsvfEligible.new(),
        ::CohortColumns::VetSquaresConfirmed.new(),
        ::CohortColumns::MissingDocuments.new(),
        ::CohortColumns::Provider.new(),
        ::CohortColumns::NextStep.new(),
        ::CohortColumns::HousingPlan.new(),
        ::CohortColumns::DateDocumentReady.new(),
        ::CohortColumns::DaysHomelessLastThreeYears.new(),
        ::CohortColumns::DaysLiterallyHomelessLastThreeYears.new(),
        ::CohortColumns::EnrolledHomelessShelter.new(),
        ::CohortColumns::EnrolledHomelessUnsheltered.new(),
        ::CohortColumns::EnrolledPermanentHousing.new(),
        ::CohortColumns::RelatedUsers.new(),
        ::CohortColumns::Active.new(),
        ::CohortColumns::LastHomelessVisit.new(),
        ::CohortColumns::NewLeaseReferral.new(),
        ::CohortColumns::VulnerabilityRank.new(),
        ::CohortColumns::ActiveCohorts.new(),
        ::CohortColumns::DestinationFromHomelessness.new(),
        ::CohortColumns::OpenEnrollments.new(),
        ::CohortColumns::Ineligible.new(),
        ::CohortColumns::ConsentConfirmed.new(),
        ::CohortColumns::DisabilityVerificationDate.new(),
        ::CohortColumns::AvailableForMatchingInCas.new(),
        ::CohortColumns::Sober.new(),
        ::CohortColumns::OriginalChronic.new(),
        ::CohortColumns::NotAVet.new(),
        ::CohortColumns::EtoCoordinatedEntryAssessmentScore.new(),
        ::CohortColumns::HouseholdMembers.new(),
        ::CohortColumns::MinimumBedroomSize.new(),
        ::CohortColumns::SpecialNeeds.new(),
        ::CohortColumns::RrhDesired.new(),
        ::CohortColumns::YouthRrhDesired.new(),
        ::CohortColumns::RrhAssessmentContactInfo.new(),
        ::CohortColumns::RrhSsvfEligible.new(),

      ]
    end

    # Attr Accessors
    available_columns.each do |column|
      attr_accessor column.column
    end

    def self.sort_directions
      {
        'desc' => 'Descending',
        'asc' => 'Ascending',
      }
    end

  end
end
