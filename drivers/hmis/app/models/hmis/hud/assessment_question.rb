###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::AssessmentQuestion < Hmis::Hud::Base
  include ::HmisStructure::AssessmentQuestion
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  self.table_name = :AssessmentQuestions
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :assessment, **hmis_relation(:AssessmentID, 'Assessment')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments, optional: true
end
