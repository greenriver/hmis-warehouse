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

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_many :custom_data_elements, as: :owner, dependent: :destroy

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true

  after_commit :warehouse_trigger_processing

  private def warehouse_trigger_processing
    return unless warehouse_columns_changed?

    # NOTE: we only really need to do this for SO at the moment, but this is future-proofing against
    # pre-processing CLS in other enrollments
    enrollment.invalidate_processing!
    return if Delayed::Job.queued?(['GrdaWarehouse::Tasks::ServiceHistory::Enrollment', 'batch_process_unprocessed!'])

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.delay(queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)).batch_process_unprocessed!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['InformationDate', 'DateDeleted']).any?
  end
end
