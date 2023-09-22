###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UserGroupMember < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :user_group, class_name: '::Hmis::UserGroup'
  belongs_to :user, class_name: 'Hmis::User'
end
