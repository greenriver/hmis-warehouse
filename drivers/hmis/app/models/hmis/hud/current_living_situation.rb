###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  alias_to_underscore [:CLSSubsidyType]

  after_commit :warehouse_trigger_processing

  private def warehouse_trigger_processing
    return unless warehouse_columns_changed?

    # NOTE: we only really need to do this for SO at the moment, but this is future-proofing against
    # pre-processing CLS in other enrollments
    enrollment.invalidate_processing!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.delay.batch_process_unprocessed!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['InformationDate', 'DateDeleted']).any?
  end
end
