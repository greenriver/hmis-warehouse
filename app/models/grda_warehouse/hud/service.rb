###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Service < Base
    include HudSharedScopes
    include ::HmisStructure::Service
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Services'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :data_source, inverse_of: :services
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_services, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :services, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :services, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :services, optional: true
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :client, through: :enrollment, inverse_of: :services
    has_one :project, through: :enrollment
    has_one :organization, through: :project

    scope :bed_night, -> { where RecordType: 200 }
    scope :path_service, -> { where(RecordType: 141) }
    scope :path_referral, -> { where(RecordType: 161) }
    scope :descending, -> { order arel_table[:DateProvided].desc }
    # really, the scope below should just be true, but it isn't; this culls things down to the most recent entry of the given type for the date
    scope :uniqueness_constraint, -> {
      st1 = arel_table
      st2 = st1.dup
      st2.table_alias = 'st2'
      where(
        st2.project(Arel.star).
          where(st2[:data_source_id].eq(st1[:data_source_id])).
          where(st2[:PersonalID].eq(st1[:PersonalID])).
          where(st2[:RecordType].eq(st1[:RecordType])).
          where(st2[:EnrollmentID].eq(st1[:EnrollmentID])).
          where(st2[:DateProvided].eq(st1[:DateProvided])).
          where(st2[:id].gt(st1[:id])).
          exists.not,
      )
    }

    scope :between, ->(start_date:, end_date:) do
      where(arel_table[:DateProvided].between(start_date..end_date))
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end
