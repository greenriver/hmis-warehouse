###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserGroup < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  has_many :access_controls, inverse_of: :user_group
  has_many :user_group_members, inverse_of: :user_group
  has_many :users, through: :user_group_members

  def add(users)
    # Force individual queries for paper_trail
    Array.wrap(users).uniq.each do |user|
      user_group_members.where(user_id: user.id).first_or_create!
    end
  end

  def remove(users)
    # Force individual queries for paper_trail
    Array.wrap(users).uniq.each do |user|
      user_group_members.where(user_id: user.id).destroy
    end
  end
end
