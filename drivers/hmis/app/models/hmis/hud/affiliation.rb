###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Affiliation < Hmis::Hud::Base
  include ::HmisStructure::Affiliation
  include ::Hmis::Hud::Concerns::Shared
  self.table_name = :Affiliation
  self.sequence_name = "public.\"#{table_name}_id_seq\""
end
