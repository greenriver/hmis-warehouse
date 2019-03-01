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

    scope :visible_in_cas, -> do
      where(visible_in_cas: true)
    end
    scope :show_on_client_dashboard, -> do
      where(show_on_client_dashboard: true)
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

      scope = case population&.to_sym
      when :housed
        housed_scope
      when :active
        active_scope
      when :ineligible
        ineligible_scope
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
          client: [:source_clients, :processed_service_history, {cohort_clients: :cohort}]
        }
      )
    end

    private def needs_client_search
      raise "call #search_clients first; scope: #{@client_search_scope.present?}; results: #{@client_search_result.count}" unless @client_search_scope.present? && @client_search_result.present?
    end

    private def at
      @at ||= GrdaWarehouse::CohortClient.arel_table
    end

    def sanitized_name
      name.gsub(/[\/\\]/, '-')
    end

    def active_scope
      @client_search_scope.where(
          at[:housed_date].eq(nil).
          or(at[:destination].eq(nil).
          or(at[:destination].eq('')))
        ).where(ineligible: [nil, false])
    end

    # should we show the housed option for the last `client_search`
    def show_housed
      needs_client_search
      housed_scope.exists?
    end

    def housed_scope
      @client_search_scope.where.not(housed_date: nil, destination: [nil, ''])
    end

    # should we show the inactive option for the last `client_search`
    def show_inactive
      needs_client_search
      ineligible_scope.exists?
    end

    def ineligible_scope
      @client_search_scope.where(ineligible: true).where(
        at[:housed_date].eq(nil).
        or(at[:destination].eq(nil).
        or(at[:destination].eq('')))
      )
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
        ::CohortColumns::ClientNotes.new(),
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
        ::CohortColumns::Race.new(),
        ::CohortColumns::Ethnicity.new(),
        ::CohortColumns::Lgbtq.new(),
        ::CohortColumns::SleepingLocation.new(),
        ::CohortColumns::ExitDestination.new(),
        ::CohortColumns::ActiveInCasMatch.new(),
        ::CohortColumns::SchoolDistrict.new(),
        ::CohortColumns::UserString1.new(),
        ::CohortColumns::UserString2.new(),
        ::CohortColumns::UserString3.new(),
        ::CohortColumns::UserString4.new(),
        ::CohortColumns::UserBoolean1.new(),
        ::CohortColumns::UserBoolean2.new(),
        ::CohortColumns::UserBoolean3.new(),
        ::CohortColumns::UserBoolean4.new(),
        ::CohortColumns::UserSelect1.new(),
        ::CohortColumns::UserSelect2.new(),
        ::CohortColumns::UserSelect3.new(),
        ::CohortColumns::UserSelect4.new(),
        ::CohortColumns::UserDate1.new(),
        ::CohortColumns::UserDate2.new(),
        ::CohortColumns::UserDate3.new(),
        ::CohortColumns::UserDate4.new(),
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
      GrdaWarehouse::Cohort.active.each(&:refresh_time_dependant_client_data)
    end

    def refresh_time_dependant_client_data(cohort_client_ids: nil)
      scope = cohort_clients
      if cohort_client_ids.present?
        scope = scope.where(id: cohort_client_ids)
      end
      scope.joins(:client).each do |cc|
        data = {
          calculated_days_homeless_on_effective_date: calculated_days_homeless(cc.client),
          days_homeless_last_three_years_on_effective_date: days_homeless_last_three_years(cc.client),
          days_literally_homeless_last_three_years_on_effective_date: days_literally_homeless_last_three_years(cc.client),
          destination_from_homelessness: destination_from_homelessness(cc.client),
          related_users: related_users(cc.client),
          disability_verification_date: disability_verification_date(cc.client),
          missing_documents: missing_documents(cc.client),
        }
        cc.update(data)
      end
    end


    private def calculated_days_homeless(client)
      client.days_homeless(on_date: effective_date || Date.today)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.homeless_counts to accept client_ids and a date
    end

    private def days_homeless_last_three_years(client)
      client.days_homeless_in_last_three_years(on_date: effective_date || Date.today)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.all_homeless_in_last_three_years to accept client_ids and a date
    end

    private def days_literally_homeless_last_three_years(client)
      client.literally_homeless_last_three_years(on_date: effective_date || Date.today)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.all_literally_homeless_last_three_years to accept client_ids and a date
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

    private def missing_documents(client)
      required_documents = GrdaWarehouse::AvailableFileTag.document_ready
      client.document_readiness(required_documents).select do |m|
        m.available == false
      end.map(&:name).join('; ')
    end

    private def disability_verification_date(client)
      client.most_recent_verification_of_disability&.created_at&.to_date
    end
  end
end
