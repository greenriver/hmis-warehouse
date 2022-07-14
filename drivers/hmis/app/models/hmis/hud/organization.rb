###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Organization < Base
  self.table_name = :Organization
  self.sequence_name = "public.\"#{table_name}_id_seq\""
end
