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

  scope :not_system, -> do
    where(system: false)
  end

  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    where(system: true)
  end

  def self.system_user
    group = find_by(name: 'System User Group', system: true)
    return group if group.present?

    group = create(name: 'System User Group', system: true)
    group.add(User.system_user)
    group
  end

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

  def self.options_for_select(include_system: false)
    return order(name: :asc).pluck(:name, :id) if include_system

    not_system.order(name: :asc).pluck(:name, :id)
  end
end
