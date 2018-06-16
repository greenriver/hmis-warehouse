module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    include ArelHelper
    extend Memoist

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

    def search_clients(page: nil, per: nil, inactive: nil, population: :active)
      @client_search_scope = if inactive.present?
        cohort_clients.joins(:client)
      else
        cohort_clients.joins(:client).where(active: true)
      end

      at = GrdaWarehouse::CohortClient.arel_table

      scope = case population.to_sym
      when :housed
        @client_search_scope.where.not(housed_date: nil, destination: [nil, '']).
          where(ineligible: [nil, false])
      when :active
        @client_search_scope.where(
          at[:housed_date].eq(nil).
          or(at[:destination].eq(nil).
          or(at[:destination].eq('')))
        ).where(ineligible: [nil, false])
      when :ineligible
        @client_search_scope.where(ineligible: true)
      else
        @client_search_scope.where(
          at[:housed_date].eq(nil).
          or(at[:destination].eq(nil).
          or(at[:destination].eq('')))
        ).where(ineligible: [nil, false])
      end
      if page.present? && per.present?
        scope = scope.order(id: :asc).page(page).per(per)
      end
      @client_search_result = scope.preload(
        {
          cohort_client_notes: :user,
          client: [:processed_service_history, {cohort_clients: :cohort}]
        }
      )
    end
    
    private def needs_client_search
      raise "call #search_clients first; scope: #{@client_search_scope.present?}; results: #{@client_search_result.count}" unless @client_search_scope.present? && @client_search_result.present?
    end

    # should we show the housed option for the last `client_search`
    def show_housed
      needs_client_search
      @client_search_scope.where.not(housed_date: nil, destination: [nil, '']).
        where(ineligible: [nil, false]).exists?
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

    def self.has_some_cohort_access user
      user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts? || user.can_edit_cohort_clients? || user.can_manage_cohorts?
    end

    def user_can_edit_cohort_clients user
      user.can_manage_cohorts? || user.can_edit_cohort_clients? || (user.can_edit_assigned_cohorts? && user.cohorts.where(id: id).exists?)
    end
    memoize :user_can_edit_cohort_clients

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
      !active?
    end

    def active?
      active_cohort?
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
        ::CohortColumns::Reported.new(),
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

    def self.prepare_active_cohorts
      client_ids = GrdaWarehouse::CohortClient.joins(:cohort, :client).merge(GrdaWarehouse::Cohort.active).distinct.pluck(:client_id)
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
      GrdaWarehouse::Cohort.active.each(&:time_dependant_client_data)
    end

    # A cache of client calculations dependent
    # on both the current time and the effective_date of this cohort
    # intended to be called only by CohortColumns::* only
    def time_dependant_client_data
      Rails.cache.fetch([self.cache_key, 'time_dependant_client_data'], expires_in: 10.hours) do
        {}.tap do |data_by_client_id|
          cohort_clients.joins(:client).map do |cc|
            data_by_client_id[cc.client_id] = {
              calculated_days_homeless: calculated_days_homeless(cc.client),
              days_homeless_last_three_years: days_homeless_last_three_years(cc.client),
              days_literally_homeless_last_three_years: days_literally_homeless_last_three_years(cc.client),
              destination_from_homelessness: destination_from_homelessness(cc.client),
              related_users: related_users(cc.client)
            }
          end
        end
      end
    end
    memoize :time_dependant_client_data

    private def calculated_days_homeless(client)
      client.days_homeless(on_date: effective_date || Date.today)
    end

    private def days_homeless_last_three_years(client)
      client.days_homeless_in_last_three_years(on_date: effective_date || Date.today)
    end

    private def days_literally_homeless_last_three_years(client)
      client.literally_homeless_last_three_years(on_date: effective_date || Date.today)
    end

    private def destination_from_homelessness(client)
      client.permanent_source_exits_from_homelessness.
        where(ex_t[:ExitDate].gteq(90.days.ago.to_date)).
        pluck(:ExitDate, :Destination).map do |exit_date, destination|
          "#{exit_date} to #{HUD.destination(destination)}"
        end.join('; ')
    end

    private def related_users(client)
      users = client.user_clients.
        non_confidential.
        active.
        pluck(:user_id, :relationship).to_h
      User.where(id: users.keys).map{|u| "#{users[u.id]} (#{u.name})"}.join('; ')
    end
  end
end
