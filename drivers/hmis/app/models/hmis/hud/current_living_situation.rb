###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CurrentLivingSituation < Hmis::Hud::Base
  include ::HmisStructure::CurrentLivingSituation
  include ::Hmis::Hud::Concerns::Shared
  self.table_name = :CurrentLivingSituation
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  include ::Hmis::Hud::Concerns::EnrollmentRelated
end
