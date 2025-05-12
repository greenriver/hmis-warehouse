# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Audit-log containing PHI
class Health::HealthVersion < HealthDbBase
  self.table_name = 'versions'
  include ::GrPaperTrailVersionBehavior

  # phi_attr :object, Phi::Bulk # contains serialize model data that depends on the model
  # phi_attr :object_changes, Phi::Bulk # contains serialize model data that depends on the model
end
