###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Service < Hmis::Hud::Base
  self.table_name = :Services
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Service
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::HasCustomDataElements
  include ::Hmis::Hud::Concerns::ServiceHistoryQueuer

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::ServiceValidator

  # On user-initiated change, validate that there is max 1 bed night per date
  validates_uniqueness_of :enrollment_id,
                          scope: [:date_provided, :data_source_id],
                          conditions: -> { bed_nights },
                          on: [:form_submission, :bed_nights_mutation]

  scope :bed_nights, -> { where(RecordType: 200) }

  after_commit :warehouse_trigger_processing

  private def warehouse_trigger_processing
    return unless enrollment && warehouse_columns_changed?

    # NOTE: we only really need to do this for bed-nights at the moment, but this is future-proofing against
    # pre-processing all services
    enrollment.invalidate_processing!
    queue_service_history_processing!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['DateProvided', 'RecordType', 'TypeProvided', 'DateDeleted']).any?
  end
end
