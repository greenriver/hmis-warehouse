###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CurrentLivingSituation < Hmis::Hud::Base
  self.table_name = :CurrentLivingSituation
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::CurrentLivingSituation
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::ServiceHistoryQueuer
  include ::Hmis::Hud::Concerns::FormSubmittable

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  # Trigger warehouse processing after create/update if certain fields changed.
  # This is called even if the transaction that created/updated the record is rolled back, so it could queue some unnecessary processing.
  # Not using the after_commit hook because it doesn't reliably pick up the saved_changes from a transaction.
  after_save :warehouse_trigger_processing

  private def warehouse_trigger_processing
    return unless enrollment && warehouse_columns_changed?

    # NOTE: we only really need to do this for SO at the moment, but this is future-proofing against
    # pre-processing CLS in other enrollments
    enrollment.invalidate_processing!
    queue_service_history_processing!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['InformationDate', 'DateDeleted']).any?
  end
end
