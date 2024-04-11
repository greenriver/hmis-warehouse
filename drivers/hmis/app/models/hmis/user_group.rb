###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UserGroup < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  include UserPermissionCache

  has_many :access_controls, inverse_of: :user_group
  has_many :user_group_members, class_name: '::Hmis::UserGroupMember', inverse_of: :user_group
  has_many :users, through: :user_group_members

  after_save :invalidate_user_permission_cache

  scope :with_user_id, ->(user_id) do
    joins(:user_group_members).
      merge(Hmis::UserGroupMember.where(user_id: user_id))
  end

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(
      arel_table[:name].matches(query).
      or(arel_table[:description].matches(query)),
    )
  end

  def self.system_user_group
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
      user_group_members.find_by(user_id: user.id)&.destroy
    end
  end

  def self.options_for_select
    order(name: :asc).pluck(:name, :id)
  end
end
