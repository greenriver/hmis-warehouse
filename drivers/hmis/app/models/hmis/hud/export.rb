###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE Export does not inherit from Base (it does not act as paranoid)
class Hmis::Hud::Export < ::GrdaWarehouseBase
  self.table_name = :Export
  self.sequence_name = "public.\"#{table_name}_id_seq\""
end
