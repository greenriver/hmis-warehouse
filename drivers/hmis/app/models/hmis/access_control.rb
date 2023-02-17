###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_group, class_name: '::Hmis::AccessGroup'
  belongs_to :role, class_name: 'Hmis::Role'
  has_many :user_access_controls, class_name: '::Hmis::UserAccessControl', inverse_of: :access_control
  has_many :users, through: :user_access_controls

  def add(users)
    (self.users + Array.wrap(users)).uniq.each do |user|
      user_access_controls.create!(user_id: user.id)
    end
  end

  def remove(users)
    user_access_controls.where(user_id: users.pluck(:id)).destroy_all
  end
end
