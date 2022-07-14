###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Project < Hmis::Hud::Base
  self.table_name = :Project
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :organization, **hmis_relation(:OrganizationID, 'Organization')

  scope :viewable_by, ->(_user) { all } # TODO: Fill in logic for this
  scope :with_project_type, ->(_project_types) { all } # TODO: Fill in logic for this
end
