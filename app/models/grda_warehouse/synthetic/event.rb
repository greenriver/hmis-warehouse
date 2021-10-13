###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Synthetic
  class Event < GrdaWarehouseBase
    self.table_name = 'synthetic_events'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :source, polymorphic: true, optional: true
    belongs_to :hud_event, class_name: 'GrdaWarehouse::Hud::Event', optional: true, primary_key: :hud_event_event_id, foreign_key: :EventID, optional: true

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
        where.not(EventID: select(:hud_event_event_id)).
        delete_all
    end

    def self.create_hud_events
      preload(:enrollment, :client, :source).find_in_batches do |batch|
        to_import = batch.map(&:hud_event_hash)
        event_source.import(
          to_import.compact,
          on_duplicate_key_update: {
            conflict_target: ['"EventID"', :data_source_id],
            columns: event_source.hmis_configuration(version: '2022').keys,
          },
        )
        batch.each.with_index do |synthetic, i|
          added = to_import[i]
          next if added.blank?

          synthetic.update(hud_event_event_id: added[:EventID])
        end
      end
    end

    def hud_event_hash
      return nil unless enrollment.present? &&
        event_date.present? &&
        event.present?

      unique_key = [enrollment.EnrollmentID, enrollment.PersonalID, event_date, enrollment.data_source_id, source.id]
      eventid = hud_event&.EventID || Digest::MD5.hexdigest(unique_key.join('_'))
      {
        EventID: eventid,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        EventDate: event_date,
        Event: event,
        ProbSolDivRRResult: client_housed_in_a_safe_alternative,
        ReferralCaseManageAfter: enrolled_in_aftercare_project,
        LocationCrisisOrPHHousing: location_of_crisis_or_ph_housing,
        ReferralResult: referral_result,
        ResultDate: result_date,
        DateCreated: source.created_at,
        DateUpdated: source.updated_at,
        UserID: user_id,
        data_source_id: enrollment.data_source_id,
        synthetic: true,
      }
    end

    private def user_id
      @user_id ||= User.setup_system_user.name
    end

    def self.event_source
      GrdaWarehouse::Hud::Event
    end
  end
end
