###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_group, class_name: '::Hmis::AccessGroup'
  belongs_to :role, class_name: 'Hmis::Role'
  belongs_to :user_group, class_name: '::Hmis::UserGroup', required: false
  has_many :users, through: :user_group

  def add(users)
    Array.wrap(users).uniq.each do |user|
      user_group_members.where(user_id: user.id).first_or_create!
    end
  end

  def remove(users)
    user_group_members.where(user_id: users.pluck(:id)).destroy_all
  end
end
