###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class Base < GrdaWarehouseBase
    self.table_name = :client_notes
    acts_as_paranoid
    validates_presence_of :note, :type

    attr_accessor :send_notification

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :user, optional: true

    scope :window_notes, -> do
      where(type: 'GrdaWarehouse::ClientNotes::WindowNote')
    end

    scope :chronic_justifications, -> do
      where(type: 'GrdaWarehouse::ClientNotes::ChronicJustification')
    end

    scope :cohort_notes, -> do
      where(type: 'GrdaWarehouse::ClientNotes::CohortNote')
    end

    scope :alerts, -> do
      where(type: 'GrdaWarehouse::ClientNotes::Alert')
    end

    scope :emergency_contact, -> do
      where(type: 'GrdaWarehouse::ClientNotes::EmergencyContact')
    end

    scope :window_varieties, -> do
      types = available_types.map(&:name)
      where(type: types)
    end

    scope :visible_by, ->(user, client) do
      if user.can_edit_client_notes?
        current_scope
      elsif user.can_view_all_window_notes?
        window_varieties
      # If the client has a release and we have permission, show all window notes
      elsif client.release_valid? && user.can_edit_window_client_notes?
        window_notes
      else
        # otherwise, only show those we created
        where(user_id: user.id)
      end
    end

    def self.type_name
      raise 'Must be implemented in sub-class'
    end

    def type_name
      self.class.type_name
    end

    def self.available_types(user = nil)
      if user&.can_edit_client_notes?
        [
          GrdaWarehouse::ClientNotes::WindowNote,
          GrdaWarehouse::ClientNotes::ChronicJustification,
          GrdaWarehouse::ClientNotes::CohortNote,
          GrdaWarehouse::ClientNotes::Alert,
          GrdaWarehouse::ClientNotes::EmergencyContact,
        ]
      else
        [
          GrdaWarehouse::ClientNotes::WindowNote,
          GrdaWarehouse::ClientNotes::Alert,
          GrdaWarehouse::ClientNotes::EmergencyContact,
        ]
      end
    end

    def destroyable_by(user)
      user.can_edit_client_notes?
    end
  end
end
