###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Inventory < Hmis::Hud::Base
  include ::HmisStructure::Inventory
  include ::Hmis::Hud::Shared
  self.table_name = :Inventory
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')

  use_enum :household_type_enum_map, ::HUD.household_types
  use_enum :availability_enum_map, ::HUD.availabilities
  use_enum :bed_type_enum_map, ::HUD.bed_types
end
