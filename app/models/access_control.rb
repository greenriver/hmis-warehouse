###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_group
  belongs_to :role
  has_many :user_access_controls, inverse_of: :access_control
  has_many :users, through: :user_access_controls

  def add(users)
    Array.wrap(users).uniq.each do |user|
      user_access_controls.where(user_id: user.id).first_or_create!
    end
  end

  def remove(users)
    user_access_controls.where(user_id: users.pluck(:id)).destroy_all
  end

  def name
    "#{role.name} x #{access_group.name}"
  end
end
