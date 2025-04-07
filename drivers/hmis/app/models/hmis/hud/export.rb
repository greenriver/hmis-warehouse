###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTE Export does not inherit from Base (it does not act as paranoid)
class Hmis::Hud::Export < ::GrdaWarehouseBase
  self.table_name = :Export
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::Export
  include ::Hmis::Hud::Concerns::Shared
end
