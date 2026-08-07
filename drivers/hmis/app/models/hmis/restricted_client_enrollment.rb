###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Database view mapping each restricted client to its enrollments, and therefore to the projects that
# can unlock it. A restricted client is visible only to users who can view clients and restricted
# clients at a project where that client is or was enrolled.
#
# Restricted clients with no enrollments appear once with a NULL enrollment_id and project_id. No
# project matches that row, so they are hidden from everyone without needing a special case here.
#
# The view exists mainly so Enrollment can filter on its own primary key: Enrollment reaches Client
# through a composite [data_source_id, PersonalID] association, which is awkward to express as a
# subquery.
#
# See docs/features/hmis/hmis-restricted-records.md
class Hmis::RestrictedClientEnrollment < GrdaWarehouseBase
  # database view
  self.table_name = 'hmis_restricted_client_enrollments'
  def readonly? = true

  belongs_to :client, class_name: 'Hmis::Hud::Client'
  belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
  belongs_to :project, class_name: 'Hmis::Hud::Project', optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  # Rows the user can unlock: the enrollment is at a project where they can view restricted clients.
  # The project set is memoized per request by UserContext, since resolving it costs several queries.
  scope :unlocked_by, ->(user) do
    where(project_id: user.policy_context.unlocked_restricted_client_project_ids)
  end

  # Restricted clients the user may not see, because none of their enrollments are at an unlocking
  # project. Callers exclude these rather than including their complement.
  scope :hidden_from, ->(user) do
    unlocked_client_ids = unlocked_by(user).select(:client_id)
    where.not(client_id: unlocked_client_ids)
  end

  def self.client_ids_hidden_from(user)
    hidden_from(user).select(:client_id)
  end

  # Callers pass this to `where.not(id: ...)`, which builds a NOT IN. A single NULL in a NOT IN list
  # matches no rows at all, so excluding the unenrolled placeholder rows is required for correctness,
  # not just tidiness.
  def self.enrollment_ids_hidden_from(user)
    hidden_from(user).where.not(enrollment_id: nil).select(:enrollment_id)
  end
end
