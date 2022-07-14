###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Client < Base
  self.table_name = :Client
  self.sequence_name = "public.\"#{table_name}_id_seq\""
end
