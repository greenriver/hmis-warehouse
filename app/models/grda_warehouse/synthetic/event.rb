module GrdaWarehouse::Synthetic
  class Event < GrdaWarehouseBase
    self.table_name = 'synthetic_events'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true

    validates_presence_of :enrollment
    validates_presence_of :client

    # Subclasses should define:
    #   event_date, event

    # Subclasses may override
    def client_housed_in_a_safe_alternative
      nil
    end
    alias_method :ProbSolDivRRResult, :client_housed_in_a_safe_alternative

    def enrolled_in_aftercare_project
      nil
    end
    alias_method :ReferralCaseManageAfter, :enrolled_in_aftercare_project

    def location_of_crisis_or_ph_housing
      nil
    end
    alias_method :LocationCrisisOrPHHousing, :location_of_crisis_or_ph_housing

    # If this is overridden, result_date must be as well.
    def referral_result
      nil
    end
    alias_method :ReferralResult, :referral_result

    def result_date
      nil
    end
    alias_method :ResultDate, :result_date
  end
end