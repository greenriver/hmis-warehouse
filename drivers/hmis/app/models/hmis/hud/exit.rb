###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Exit < Hmis::Hud::Base
  self.table_name = :Exit
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Exit
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::HasCustomDataElements
  include ::Hmis::Hud::Concerns::ServiceHistoryQueuer

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::ExitValidator

  after_commit :warehouse_trigger_processing

  def aftercare_methods
    HudUtility2024.aftercare_method_fields.select { |k| send(k) == 1 }.values
  end

  def counseling_methods
    HudUtility2024.counseling_method_fields.select { |k| send(k) == 1 }.values
  end

  private def warehouse_trigger_processing
    return unless enrollment && warehouse_columns_changed?

    enrollment.invalidate_processing!
    queue_service_history_processing!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['ExitDate', 'DateDeleted']).any?
  end
end
