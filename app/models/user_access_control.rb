###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserAccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_control
  belongs_to :user
end
