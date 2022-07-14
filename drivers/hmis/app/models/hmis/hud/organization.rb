###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Organization < Hmis::Hud::Base
  self.table_name = :Organization
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  has_many :projects, **hmis_relation(:OrganizationID, 'Project')

  scope :viewable_by, ->(_user) { all } # TODO: Fill in logic for this
end
