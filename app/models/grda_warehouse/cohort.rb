module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    acts_as_paranoid
    validates_presence_of :name
    serialize :column_state, Array

    has_many :cohort_clients, dependent: :destroy
    has_many :clients, through: :cohort_clients, class_name: 'GrdaWarehouse::Hud::Client'

    attr_accessor :client_ids

    # FIXME  It is not currently known what will allow someone to see or edit a cohort
    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.can_edit_cohort_clients? || user.can_manage_cohorts?
        current_scope
      else
        none
      end
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
