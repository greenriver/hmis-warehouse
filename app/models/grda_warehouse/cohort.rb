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

    def self.has_some_cohort_access user
      user.can_view_assigned_cohorts? || user.can_edit_assigned_cohorts? || user.can_edit_cohort_clients? || user.can_manage_cohorts?
    end

    def user_can_edit_cohort_clients user
      user.can_edit_assigned_cohorts? || user.can_edit_cohort_clients? || user.can_manage_cohorts?
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
      column_state&.select(&:visible)&.presence || self.class.available_columns
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
        ::CohortColumns::HousingTrackEnrolled.new(),
        ::CohortColumns::VaEligible.new(),
        ::CohortColumns::VashEligible.new(),
        ::CohortColumns::Chapter115.new(),
        ::CohortColumns::Veteran.new(),
        ::CohortColumns::Notes.new(),
        ::CohortColumns::VispdatScore.new(),
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
        ::CohortColumns::EnrolledHomelessShelter.new(),
        ::CohortColumns::EnrolledHomelessUnsheltered.new(),
        ::CohortColumns::EnrolledPermanentHousing.new(),
        ::CohortColumns::RelatedUsers.new(),
        ::CohortColumns::Active.new(),
        ::CohortColumns::LastHomelessVisit.new(),
        ::CohortColumns::NewLeaseReferral.new(),
        ::CohortColumns::VulnerabilityRank.new(),
        ::CohortColumns::ActiveCohorts.new(),
      ]
    end

    def self.setup_column_accessors(columns)
      columns.each do |column|
        attr_accessor column.column
      end
    end

    # Attr Accessors
    setup_column_accessors(available_columns)

  end
end
