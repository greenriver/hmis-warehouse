###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Inventory < Base
  self.table_name = :Inventory
  self.sequence_name = "public.\"#{table_name}_id_seq\""
end
