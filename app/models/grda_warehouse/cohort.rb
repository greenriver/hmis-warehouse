###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'

module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    include ArelHelper
    include AccessGroups
    extend Memoist

    acts_as_paranoid
    validates_presence_of :name
    validates :days_of_inactivity, numericality: { only_integer: true, allow_nil: true }
    validates :static_column_count, numericality: { only_integer: true }
    serialize :column_state, Array

    after_create :maintain_system_group

    has_many :cohort_clients, dependent: :destroy
    has_many :clients, through: :cohort_clients, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :tags, class_name: 'Cas::Tag', optional: true

    has_many :group_viewable_entities, class_name: 'GrdaWarehouse::GroupViewableEntity', foreign_key: :entity_id

    attr_accessor :client_ids, :user_ids

    scope :active, -> do
      where(active_cohort: true)
    end

    scope :active_user, -> do
      where(active_cohort: true, system_cohort: false)
    end

    scope :inactive, -> do
      where(active_cohort: false, system_cohort: false)
    end

    scope :visible_in_cas, -> do
      where(visible_in_cas: true)
    end

    scope :show_on_client_dashboard, -> do
      where(show_on_client_dashboard: true)
    end

    scope :system_cohorts, -> do
      where(system_cohort: true)
    end

    scope :viewable_by, ->(user) do
      if user.can_edit_cohort_clients? || user.can_manage_cohorts?
        current_scope
      elsif user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts?
        if current_scope.present?
          current_scope.merge(user.cohorts)
        else
          user.cohorts
        end
      else
        none
      end
    end

    scope :editable_by, ->(user) do
      if user.can_edit_cohort_clients? || user.can_manage_cohorts?
        current_scope
      elsif user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts?
        if current_scope.present?
          current_scope.merge(user.cohorts)
        else
          user.cohorts
        end
      else
        none
      end
    end

    def search_clients(page: nil, per: nil, population: :active, user:)
      @client_search_scope = cohort_clients.joins(:client)

      scope = case population&.to_sym
      when :housed
        housed_scope
      when :active
        active_scope.where(active: true)
      when :ineligible
        ineligible_scope
      when :inactive
        inactive_scope(user)
      else # active
        active_scope.where(active: true)
      end
      scope = scope.order(id: :asc).page(page).per(per) if page.present? && per.present?
      @client_search_result = scope.preload(
        :cohort_client_changes,
        {
          cohort_client_notes: :user,
          client: [
            :source_clients,
            :processed_service_history,
            {
              cohort_clients: :cohort,
            },
          ],
        },
      )
    end

    private def at
      @at ||= GrdaWarehouse::CohortClient.arel_table
    end

    def sanitized_name
      # See https://www.keynotesupport.com/excel-basics/worksheet-names-characters-allowed-prohibited.shtml
      name.gsub(/['\*\/\\\?\[\]\:]/, '-')
    end

    def active_scope
      @client_search_scope.where(
        at[:housed_date].eq(nil).
        or(at[:destination].eq(nil).
        or(at[:destination].eq(''))),
      ).where(ineligible: [nil, false])
    end

    # only administrator should have access to the inactive clients
    def inactive_scope user
      return @client_search_scope.none unless user.can_manage_cohorts? || user.can_edit_cohort_clients?

      @client_search_scope.where(active: false)
    end

    def show_inactive user
      return false unless user.can_manage_cohorts? || user.can_edit_cohort_clients?

      inactive_scope(user).exists?
    end

    # should we show the housed option for the last `client_search`
    def show_housed
      housed_scope.exists?
    end

    def housed_scope
      @client_search_scope.where.not(housed_date: nil, destination: [nil, ''])
    end

    # should we show the inactive option for the last `client_search`
    def show_ineligible
      ineligible_scope.exists?
    end

    def ineligible_scope
      @client_search_scope.where(ineligible: true).where(
        at[:housed_date].eq(nil).
        or(at[:destination].eq(nil).
        or(at[:destination].eq(''))),
      )
    end

    # full un-paginated scope for the last `client_search`
    attr_reader :client_search_scope

    # paginated/preloaded scope for the last `client_search`
    attr_reader :client_search_result

    def self.has_some_cohort_access user # rubocop:disable  Naming/PredicateName
      user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts? || user.can_edit_cohort_clients? || user.can_manage_cohorts?
    end

    def user_can_edit_cohort_clients user
      user.can_manage_cohorts? || user.can_edit_cohort_clients? || (user.can_edit_assigned_cohorts? && user.cohorts.where(id: id).exists?)
    end
    memoize :user_can_edit_cohort_clients

    def inactive?
      !active?
    end

    def active?
      active_cohort?
    end

    def cas_tag_name
      Cas::Tag.find(tag_id)&.name
    rescue ActiveRecord::RecordNotFound, PG::ConnectionBad
      nil
    end

    def visible_columns(user:)
      return self.class.default_visible_columns unless column_state.present?

      columns = column_state&.select(&:visible)&.presence || self.class.available_columns
      columns.each do |column|
        column.current_user = user
      end
    end

    def self.default_visible_columns
      [
        ::CohortColumns::LastName.new,
        ::CohortColumns::FirstName.new,
      ]
    end

    def self.available_columns # rubocop:disable Metrics/AbcSize
      [
        ::CohortColumns::LastName.new,
        ::CohortColumns::FirstName.new,
        ::CohortColumns::Rank.new,
        ::CohortColumns::Age.new,
        ::CohortColumns::Gender.new,
        ::CohortColumns::Ssn.new,
        ::CohortColumns::ClientId.new,
        ::CohortColumns::CalculatedDaysHomeless.new,
        ::CohortColumns::AdjustedDaysHomeless.new,
        ::CohortColumns::AdjustedDaysHomelessLastThreeYears.new,
        ::CohortColumns::AdjustedDaysLiterallyHomelessLastThreeYears.new,
        ::CohortColumns::DaysHomelessPlusOverrides.new,
        ::CohortColumns::FirstDateHomeless.new,
        ::CohortColumns::Chronic.new,
        ::CohortColumns::Agency.new,
        ::CohortColumns::CaseManager.new,
        ::CohortColumns::HousingManager.new,
        ::CohortColumns::HousingSearchAgency.new,
        ::CohortColumns::HousingOpportunity.new,
        ::CohortColumns::LegalBarriers.new,
        ::CohortColumns::CriminalRecordStatus.new,
        ::CohortColumns::DocumentReady.new,
        ::CohortColumns::SifEligible.new,
        ::CohortColumns::SensoryImpaired.new,
        ::CohortColumns::HousedDate.new,
        ::CohortColumns::Destination.new,
        ::CohortColumns::SubPopulation.new,
        ::CohortColumns::IndividualInMostRecentEnrollment.new,
        ::CohortColumns::StFrancisHouse.new,
        ::CohortColumns::LastGroupReviewDate.new,
        ::CohortColumns::LastDateApproached.new,
        ::CohortColumns::PreContemplativeLastDateApproached.new,
        ::CohortColumns::HousingTrackSuggested.new,
        ::CohortColumns::PrimaryHousingTrackSuggested.new,
        ::CohortColumns::HousingTrackEnrolled.new,
        ::CohortColumns::VaEligible.new,
        ::CohortColumns::VashEligible.new,
        ::CohortColumns::Chapter115.new,
        ::CohortColumns::Veteran.new,
        ::CohortColumns::ClientNotes.new,
        ::CohortColumns::Notes.new,
        ::CohortColumns::VispdatScore.new,
        ::CohortColumns::VispdatPriorityScore.new,
        ::CohortColumns::HousingNavigator.new,
        ::CohortColumns::LocationType.new,
        ::CohortColumns::Location.new,
        ::CohortColumns::Status.new,
        ::CohortColumns::SsvfEligible.new,
        ::CohortColumns::VetSquaresConfirmed.new,
        ::CohortColumns::MissingDocuments.new,
        ::CohortColumns::Provider.new,
        ::CohortColumns::NextStep.new,
        ::CohortColumns::HousingPlan.new,
        ::CohortColumns::DateDocumentReady.new,
        ::CohortColumns::DaysHomelessLastThreeYears.new,
        ::CohortColumns::DaysLiterallyHomelessLastThreeYears.new,
        ::CohortColumns::EnrolledHomelessShelter.new,
        ::CohortColumns::EnrolledHomelessUnsheltered.new,
        ::CohortColumns::EnrolledPermanentHousing.new,
        ::CohortColumns::RelatedUsers.new,
        ::CohortColumns::Active.new,
        ::CohortColumns::LastHomelessVisit.new,
        ::CohortColumns::OngoingEs.new,
        ::CohortColumns::OngoingSo.new,
        ::CohortColumns::OngoingSh.new,
        ::CohortColumns::OngoingTh.new,
        ::CohortColumns::OngoingRrh.new,
        ::CohortColumns::OngoingPsh.new,
        ::CohortColumns::NewLeaseReferral.new,
        ::CohortColumns::VulnerabilityRank.new,
        ::CohortColumns::ActiveCohorts.new,
        ::CohortColumns::DestinationFromHomelessness.new,
        ::CohortColumns::HmisDestination.new,
        ::CohortColumns::OpenEnrollments.new,
        ::CohortColumns::Ineligible.new,
        ::CohortColumns::ConsentConfirmed.new,
        ::CohortColumns::DisabilityVerificationDate.new,
        ::CohortColumns::AvailableForMatchingInCas.new,
        ::CohortColumns::DaysSinceCasMatch.new,
        ::CohortColumns::Sober.new,
        ::CohortColumns::OriginalChronic.new,
        ::CohortColumns::NotAVet.new,
        ::CohortColumns::EtoCoordinatedEntryAssessmentScore.new,
        ::CohortColumns::HouseholdMembers.new,
        ::CohortColumns::MinimumBedroomSize.new,
        ::CohortColumns::SpecialNeeds.new,
        ::CohortColumns::RrhDesired.new,
        ::CohortColumns::YouthRrhDesired.new,
        ::CohortColumns::RrhAssessmentContactInfo.new,
        ::CohortColumns::RrhSsvfEligible.new,
        ::CohortColumns::Reported.new,
        ::CohortColumns::Race.new,
        ::CohortColumns::Ethnicity.new,
        ::CohortColumns::Lgbtq.new,
        ::CohortColumns::LgbtqFromHmis.new,
        ::CohortColumns::SleepingLocation.new,
        ::CohortColumns::ExitDestination.new,
        ::CohortColumns::ActiveInCasMatch.new,
        ::CohortColumns::SchoolDistrict.new,
        ::CohortColumns::AssessmentScore.new,
        ::CohortColumns::VispdatScoreManual.new,
        ::CohortColumns::DaysOnCohort.new,
        ::CohortColumns::CasVashEligible.new,
        ::CohortColumns::DateAddedToCohort.new,
        ::CohortColumns::PreviousRemovalReason.new,
        ::CohortColumns::HealthPrioritized.new,
        ::CohortColumns::UserString1.new,
        ::CohortColumns::UserString2.new,
        ::CohortColumns::UserString3.new,
        ::CohortColumns::UserString4.new,
        ::CohortColumns::UserString5.new,
        ::CohortColumns::UserString6.new,
        ::CohortColumns::UserString7.new,
        ::CohortColumns::UserString8.new,
        ::CohortColumns::UserBoolean1.new,
        ::CohortColumns::UserBoolean2.new,
        ::CohortColumns::UserBoolean3.new,
        ::CohortColumns::UserBoolean4.new,
        ::CohortColumns::UserBoolean5.new,
        ::CohortColumns::UserBoolean6.new,
        ::CohortColumns::UserBoolean7.new,
        ::CohortColumns::UserBoolean8.new,
        ::CohortColumns::UserBoolean9.new,
        ::CohortColumns::UserBoolean10.new,
        ::CohortColumns::UserBoolean11.new,
        ::CohortColumns::UserBoolean12.new,
        ::CohortColumns::UserBoolean13.new,
        ::CohortColumns::UserBoolean14.new,
        ::CohortColumns::UserBoolean15.new,
        ::CohortColumns::UserBoolean16.new,
        ::CohortColumns::UserBoolean17.new,
        ::CohortColumns::UserBoolean18.new,
        ::CohortColumns::UserBoolean19.new,
        ::CohortColumns::UserBoolean20.new,
        ::CohortColumns::UserBoolean21.new,
        ::CohortColumns::UserBoolean22.new,
        ::CohortColumns::UserBoolean23.new,
        ::CohortColumns::UserBoolean24.new,
        ::CohortColumns::UserBoolean25.new,
        ::CohortColumns::UserBoolean26.new,
        ::CohortColumns::UserBoolean27.new,
        ::CohortColumns::UserBoolean28.new,
        ::CohortColumns::UserBoolean29.new,
        ::CohortColumns::UserBoolean30.new,
        ::CohortColumns::UserSelect1.new,
        ::CohortColumns::UserSelect2.new,
        ::CohortColumns::UserSelect3.new,
        ::CohortColumns::UserSelect4.new,
        ::CohortColumns::UserSelect5.new,
        ::CohortColumns::UserSelect6.new,
        ::CohortColumns::UserSelect7.new,
        ::CohortColumns::UserSelect8.new,
        ::CohortColumns::UserSelect9.new,
        ::CohortColumns::UserSelect10.new,
        ::CohortColumns::UserSelect11.new,
        ::CohortColumns::UserSelect12.new,
        ::CohortColumns::UserSelect13.new,
        ::CohortColumns::UserSelect14.new,
        ::CohortColumns::UserSelect15.new,
        ::CohortColumns::UserSelect16.new,
        ::CohortColumns::UserSelect17.new,
        ::CohortColumns::UserSelect18.new,
        ::CohortColumns::UserSelect19.new,
        ::CohortColumns::UserSelect20.new,
        ::CohortColumns::UserSelect21.new,
        ::CohortColumns::UserSelect22.new,
        ::CohortColumns::UserSelect23.new,
        ::CohortColumns::UserSelect24.new,
        ::CohortColumns::UserSelect25.new,
        ::CohortColumns::UserSelect26.new,
        ::CohortColumns::UserSelect27.new,
        ::CohortColumns::UserSelect28.new,
        ::CohortColumns::UserSelect28.new,
        ::CohortColumns::UserSelect30.new,
        ::CohortColumns::UserDate1.new,
        ::CohortColumns::UserDate2.new,
        ::CohortColumns::UserDate3.new,
        ::CohortColumns::UserDate4.new,
        ::CohortColumns::UserDate5.new,
        ::CohortColumns::UserDate6.new,
        ::CohortColumns::UserDate7.new,
        ::CohortColumns::UserDate8.new,
        ::CohortColumns::UserDate9.new,
        ::CohortColumns::UserDate10.new,
        ::CohortColumns::UserDate11.new,
        ::CohortColumns::UserDate12.new,
        ::CohortColumns::UserDate13.new,
        ::CohortColumns::UserDate14.new,
        ::CohortColumns::UserDate15.new,
        ::CohortColumns::UserDate16.new,
        ::CohortColumns::UserDate17.new,
        ::CohortColumns::UserDate18.new,
        ::CohortColumns::UserDate19.new,
        ::CohortColumns::UserDate20.new,
        ::CohortColumns::UserDate21.new,
        ::CohortColumns::UserDate22.new,
        ::CohortColumns::UserDate23.new,
        ::CohortColumns::UserDate24.new,
        ::CohortColumns::UserDate25.new,
        ::CohortColumns::UserDate26.new,
        ::CohortColumns::UserDate27.new,
        ::CohortColumns::UserDate28.new,
        ::CohortColumns::UserDate29.new,
        ::CohortColumns::UserDate30.new,
        ::CohortColumns::UserNumeric1.new,
        ::CohortColumns::UserNumeric2.new,
        ::CohortColumns::UserNumeric3.new,
        ::CohortColumns::UserNumeric4.new,
        ::CohortColumns::UserNumeric5.new,
        ::CohortColumns::UserNumeric6.new,
        ::CohortColumns::UserNumeric7.new,
        ::CohortColumns::UserNumeric8.new,
        ::CohortColumns::UserNumeric9.new,
        ::CohortColumns::UserNumeric10.new,
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

    def self.threshold_keys
      (1..visible_thresholds).map do |i|
        [
          "threshold_row_#{i}",
          "threshold_color_#{i}",
          "threshold_label_#{i}",
        ]
      end.flatten
    end

    def self.visible_thresholds
      3
    end

    def self.prepare_active_cohorts
      client_ids = GrdaWarehouse::CohortClient.joins(:cohort, :client).merge(GrdaWarehouse::Cohort.active).distinct.pluck(:client_id)
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
      GrdaWarehouse::Cohort.active.each(&:refresh_time_dependant_client_data)
    end

    def refresh_time_dependant_client_data(cohort_client_ids: nil)
      scope = cohort_clients
      scope = scope.where(id: cohort_client_ids) if cohort_client_ids.present?
      scope.joins(:client).each do |cc|
        data = {
          calculated_days_homeless_on_effective_date: calculated_days_homeless(cc.client),
          days_homeless_last_three_years_on_effective_date: days_homeless_last_three_years(cc.client),
          days_literally_homeless_last_three_years_on_effective_date: days_literally_homeless_last_three_years(cc.client),
          destination_from_homelessness: destination_from_homelessness(cc.client),
          related_users: related_users(cc.client),
          disability_verification_date: disability_verification_date(cc.client),
          missing_documents: missing_documents(cc.client),
          days_homeless_plus_overrides: days_homeless_plus_overrides(cc.client),
          individual_in_most_recent_homeless_enrollment: individual_in_most_recent_homeless_enrollment(cc.client),
        }
        cc.update(data)
      end
    end

    private def calculated_days_homeless(client)
      client.days_homeless(on_date: effective_date || Date.current)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.homeless_counts to accept client_ids and a date
    end

    private def days_homeless_last_three_years(client)
      client.days_homeless_in_last_three_years(on_date: effective_date || Date.current)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.all_homeless_in_last_three_years to accept client_ids and a date
    end

    private def days_literally_homeless_last_three_years(client)
      client.literally_homeless_last_three_years(on_date: effective_date || Date.current)

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

    private def individual_in_most_recent_homeless_enrollment(client)
      most_recent_enrollment = client.service_history_enrollments.entry.homeless.order(first_date_in_program: :desc).first
      most_recent_enrollment&.presented_as_individual
    end

    private def related_users(client)
      users = client.user_clients.
        non_confidential.
        active.
        pluck(:user_id, :relationship).to_h
      User.where(id: users.keys).map { |u| "#{users[u.id]} (#{u.name})" }.join('; ')
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

    private def days_homeless_plus_overrides(client)
      client.processed_service_history&.days_homeless_plus_overrides
    end

    private def maintain_system_group
      AccessGroup.delayed_system_group_maintenance(group: :cohorts)
    end
  end
end
