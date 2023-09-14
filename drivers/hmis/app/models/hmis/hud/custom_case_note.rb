###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomCaseNote < Hmis::Hud::Base
  self.table_name = :CustomCaseNote
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  alias_to_underscore [:CustomCaseNoteID, :PersonalID, :EnrollmentID]

end
