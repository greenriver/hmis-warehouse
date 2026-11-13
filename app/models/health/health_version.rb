###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: Audit-log containing PHI
class Health::HealthVersion < HealthDbBase
  self.table_name = 'versions'
  include ::GrPaperTrailVersionBehavior

  # phi_attr :object, Phi::Bulk # contains serialize model data that depends on the model
  # phi_attr :object_changes, Phi::Bulk # contains serialize model data that depends on the model
end
