###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::IncomeBenefit < Hmis::Hud::Base
  include ::HmisStructure::IncomeBenefit
  include ::Hmis::Hud::Shared
  self.table_name = :IncomeBenefits
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
end
