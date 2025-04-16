###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::AssessmentQuestion < Hmis::Hud::Base
  self.table_name = :AssessmentQuestions
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::AssessmentQuestion
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :assessment, **hmis_relation(:AssessmentID, 'Assessment')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments, optional: true
end
