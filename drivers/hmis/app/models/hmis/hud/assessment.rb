###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Assessment < Hmis::Hud::Base
  include ::HmisStructure::Assessment
  include ::Hmis::Hud::Shared
  self.table_name = :Assessment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')

  use_enum :assessment_types_enum_map, ::HUD.assessment_types
  use_enum :assessment_levels_enum_map, ::HUD.assessment_levels
  use_enum :prioritization_statuses_enum_map, ::HUD.prioritization_statuses
end
