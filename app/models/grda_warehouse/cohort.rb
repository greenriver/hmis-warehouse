module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    validates_presence_of :name

    has_many :cohort_clients
    has_many :clients, through: :cohort_clients, class_name: 'GrdaWarehouse::Hud::Client'

    # FIXME  It is not currently known what will allow someone to see or edit a cohort
    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.can_view_cohorts? || user.can_edit_cohorts?
        current_scope
      else
        none
      end
    end

    # FIXME, this needs a mechanism to store visible columns and order in visible_state
    # Each of these 
    def visible_columns
      [
        ::CohortColumns::Agency.new(),
        ::CohortColumns::CaseManager.new(),
        ::CohortColumns::HousingManager.new(),
        # Column.new({column: :housing_search_agency, title: 'Housing Search Agency'}),
        # Column.new({column: :housing_opportunity, title: 'Housing Opportunity'}),
        # Column.new({column: :legal_barriers, title: 'Legal Barriers'}),
        # Column.new({column: :criminal_record_status, title: 'Criminal Record Status'}),
        # FIXME there are more
      ]
    end

  end
end