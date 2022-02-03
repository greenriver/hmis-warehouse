###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessGroupMember < ApplicationRecord
  acts_as_paranoid

  belongs_to :access_group, optional: true
  belongs_to :user, optional: true
end
