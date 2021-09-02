###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

      create_hud_events

      # Clean up orphans in HUD table
      event_source.
        synthetic.
        where.not(id: select(:hud_event_id)).
        delete_all
    end

    def self.create_hud_events
      preload(:enrollment, :client, :source).find_in_batches do |batch|
        event_source.import(
          batch.map(&:hud_event_hash).compact,
          on_duplicate_key_update: {
            conflict_target: ['"EventID"', :data_source_id],
            columns: event_source.hmis_configuration.keys,
          },
        )
      end
    end

    def hud_event_hash
      return nil unless enrollment.present? &&
        client.present? &&
        event_date.present? &&
        event.present?

      {
        EventID: hud_event&.EventID || SecureRandom.uuid.gsub(/-/, ''),
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: client.PersonalID,
        EventDate: event_date,
        Event: event,
        ProbSolDivRRResult: client_housed_in_a_safe_alternative,
        ReferralCaseManageAfter: enrolled_in_aftercare_project,
        LocationCrisisorPHHousing: location_of_crisis_or_ph_housing, # NOTE: case should LocationCrisisOrPHHousing
        ReferralResult: referral_result,
        ResultDate: result_date,
        DateCreated: source.created_at,
        DateUpdated: source.updated_at,
        UserID: user_id,
        data_source_id: ds.id,
        synthetic: true,
      }
    end

    private def user_id
      @user_id ||= User.setup_system_user.name
    end

    private def ds
      @ds ||= GrdaWarehouse::DataSource.where(short_name: data_source).first_or_create do |ds|
        ds.name = data_source
        ds.authoritative = true
        ds.authoritative_type = :synthetic
      end
    end

    def self.event_source
      GrdaWarehouse::Hud::Event
    end
  end
end
