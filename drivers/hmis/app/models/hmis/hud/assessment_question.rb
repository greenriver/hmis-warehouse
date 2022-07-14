###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::AssessmentQuestion < Hmis::Hud::Base
  self.table_name = :AssessmentQuestions
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :assessment, **hmis_relation(:AssessmentID, 'Assessment')
end
