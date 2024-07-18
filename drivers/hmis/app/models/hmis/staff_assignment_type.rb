###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::StaffAssignmentType < Hmis::HmisBase
  acts_as_paranoid
  validates :name, presence: true, uniqueness: true

  # todo @martha - add to_pick_list here
end
