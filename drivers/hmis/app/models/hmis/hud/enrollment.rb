###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Enrollment < Hmis::Hud::Base
  include ::HmisStructure::Enrollment
  include ::Hmis::Hud::Shared
  self.table_name = :Enrollment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  delegate :exit_date, to: :exit, allow_nil: true

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  has_one :exit, **hmis_relation(:EnrollmentID, 'Exit')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
end
