###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class Base < GrdaWarehouseBase
    self.table_name = :client_notes
    acts_as_paranoid
    validates_presence_of :note, :type

    attr_accessor :send_notification

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :user

    scope :window_notes, -> do
      where(type: 'GrdaWarehouse::ClientNotes::WindowNote')
    end

    scope :chronic_justifications, -> do
      where(type: 'GrdaWarehouse::ClientNotes::ChronicJustification')
    end

    scope :cohort_notes, -> do
      where(type: 'GrdaWarehouse::ClientNotes::CohortNote')
    end

    scope :visible_by, -> (user, client) do
      if user.can_edit_client_notes?
        current_scope
      # If the client has a release and we have permission, show all window notes
      elsif client.release_valid? && user.can_edit_window_client_notes?
        window_notes
      else
        # otherwise, only show those we created
        where(user_id: user.id)
      end
    end

    def self.type_name
      raise "Must be implemented in sub-class"
    end

    def type_name
      self.class.type_name
    end

    def self.available_types
      [
        GrdaWarehouse::ClientNotes::WindowNote,
        GrdaWarehouse::ClientNotes::ChronicJustification,
        GrdaWarehouse::ClientNotes::CohortNote,
      ]
    end

    def user_can_destroy?(user)
       user.id == self.user_id
    end
  end
end

