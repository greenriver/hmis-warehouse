###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::StaffAssignmentRelationship < Hmis::HmisBase
  # Note that this model isn't currently tied to a data source, which means that if we have multiple HMISes
  # within the same installation, they will all see the same options for StaffAssignmentRelationship.
  # We could change this if the need arises.
  acts_as_paranoid
  validates :name, presence: true, uniqueness: true

  def to_pick_list_option
    {
      code: id,
      label: name,
    }
  end
end
