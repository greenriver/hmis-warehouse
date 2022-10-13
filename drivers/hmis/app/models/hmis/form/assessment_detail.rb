###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::AssessmentDetail < ::GrdaWarehouseBase
  include Hmis::Hud::HasEnums
  self.table_name = :hmis_assessment_details
  belongs_to :assessment, class_name: 'Hmis::Hud::Assessment'
  belongs_to :definition

  use_enum :data_collection_stage_enum_map, ::HUD.data_collection_stages
end
