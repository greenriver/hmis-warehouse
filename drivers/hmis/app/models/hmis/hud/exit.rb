###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::Exit < Hmis::Hud::Base
  self.table_name = :Exit
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Exit
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::FormSubmittable
  include ::Hmis::Hud::Concerns::ServiceHistoryQueuer
  include ::Hmis::MarkClientAsDirtyBehavior

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::ExitValidator

  after_save :warehouse_trigger_processing

  scope :auto_exited, -> { where.not(auto_exited: nil) }

  def aftercare_methods
    HudHelper.util.aftercare_method_fields.select { |k| send(k) == 1 }.values
  end

  def counseling_methods
    HudHelper.util.counseling_method_fields.select { |k| send(k) == 1 }.values
  end

  # Hmis::MarkClientAsDirtyBehavior hook
  protected def ce_affected_household_keys
    # Only ExitDate changes household membership. Soft delete writes DateDeleted via update_columns, so it isn't in
    # saved_changes; check deleted? instead.
    return [] unless deleted? || saved_change_to_attribute?('ExitDate')
    return [] unless enrollment&.household_id

    [[enrollment.data_source_id, enrollment.household_id]]
  end

  private def warehouse_trigger_processing
    return unless enrollment && warehouse_columns_changed?

    enrollment.invalidate_processing!
    queue_service_history_processing!
  end

  private def warehouse_columns_changed?
    # Re-process when there are changes to any fields used in GrdaWarehouse::Tasks::ServiceHistory rebuild_service_history
    (saved_changes.keys & ['ExitDate', 'Destination', 'HousingAssessment', 'DateDeleted']).any?
  end
end
