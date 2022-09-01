###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Exit < Base
    include HudSharedScopes
    include ::HmisStructure::Exit
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Exit'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :exit, optional: true
    belongs_to :data_source, inverse_of: :exits
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_exits, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :exits, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :exits, optional: true
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :client, through: :enrollment, inverse_of: :exits
    has_one :project, through: :enrollment
    has_one :destination_client, through: :enrollment

    scope :permanent, -> do
      where(Destination: ::HUD.permanent_destinations)
    end

    scope :closed_within_range, ->(range) do
      where(ExitDate: range)
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end
