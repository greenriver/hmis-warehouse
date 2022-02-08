###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Audit-log containing PHI
class Health::HealthVersion < PaperTrail::Version
  establish_connection DB_HEALTH

  # phi_attr :object, Phi::Bulk # contains serialize model data that depends on the model
  # phi_attr :object_changes, Phi::Bulk # contains serialize model data that depends on the model
end
