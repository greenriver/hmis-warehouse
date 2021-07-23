###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: the following assumptions are currently made for data coming from CAS (as these are added to the assessments in CAS this may change)
# 1. 4.19.7 PrioritizationStatus - everyone in CAS is on the list (1)
# 2. 4.19.4 AssessmentLevel - all assessments are housing needs assessments (2)
# 3. 4.19.3 AssessmentType - are all virtual (2)
module CasCeEvents::GrdaWarehouse
  class CasCeAssessment < GrdaWarehouseBase
    self.table_name = 'cas_ce_assessments'

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :hmis_client_id
    has_many :program_to_projects, foreign_key: :program_id
    has_many :projects, through: :program_to_projects
  end
end
