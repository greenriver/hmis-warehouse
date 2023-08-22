###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserGroupMember < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :user_group, inverse_of: :user_group_members
  belongs_to :user, inverse_of: :user_group_members
end
