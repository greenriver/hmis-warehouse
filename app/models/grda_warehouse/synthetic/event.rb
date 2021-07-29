module GrdaWarehouse::Synthetic
  class Event < GrdaWarehouseBase
    self.table_name = 'synthetic_events'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true
    belongs_to :hud_event, class_name: 'GrdaWarehouse::Hud::Event', optional: true

    validates_presence_of :enrollment
    validates_presence_of :client

    # Subclasses must define:
    #   event_date, event, data_source

    # Subclasses may override
    def client_housed_in_a_safe_alternative
      nil
    end
    alias ProbSolDivRRResult client_housed_in_a_safe_alternative

    def enrolled_in_aftercare_project
      nil
    end
    alias ReferralCaseManageAfter enrolled_in_aftercare_project

    def location_of_crisis_or_ph_housing
      nil
    end
    alias LocationCrisisOrPHHousing location_of_crisis_or_ph_housing

    # If this is overridden, result_date must be as well.
    def referral_result
      nil
    end
    alias ReferralResult referral_result

    def result_date
      nil
    end
    alias ResultDate result_date

    def self.hud_sync
      # Import synthetic events
      GrdaWarehouse::Synthetic.available_event_types.each do |class_name|
        class_name.constantize.sync
      end

      #  Create HUD events from synthetic events
      find_each(&:hud_sync)

      # Clean up orphans in HUD table
      GrdaWarehouse::Hud::Event.
        where(synthetic: true).
        where.not(id: select(:hud_event_id)).
        delete_all
    end

    def hud_sync
      ds = GrdaWarehouse::DataSource.find_by(short_name: data_source)
      return unless ds.present?

      hud_assessment_hash = {
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: client.PersonalID,
        EventDate: event_date,
        Event: event,
        ProbSolDivRRResult: client_housed_in_a_safe_alternative,
        ReferralCaseManageAfter: enrolled_in_aftercare_project,
        LocationCrisisOrPHHousing: location_of_crisis_or_ph_housing,
        ReferralResult: referral_result,
        ResultDate: result_date,
        data_source_id: ds.id,
        synthetic: true,
      }

      if hud_assessment.nil?
        hud_assessment_hash[:EventID] = SecureRandom.uuid.gsub(/-/, '')
        create_hud_event(hud_assessment_hash)
      else
        hud_event.update(hud_assessment_hash)
      end
    end
  end
end
