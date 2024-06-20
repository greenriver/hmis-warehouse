###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# part of the "new" permission system
#
class UserGroup < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  include UserPermissionCache

  has_many :access_controls, inverse_of: :user_group
  has_many :user_group_members, inverse_of: :user_group
  has_many :users, through: :user_group_members

  after_save :invalidate_user_permission_cache

  scope :not_system, -> do
    where(system: false)
  end

  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    where(system: true)
  end

  scope :with_user_id, ->(user_id) do
    joins(:user_group_members).
      merge(UserGroupMember.where(user_id: user_id))
  end

  def self.system_user_group
    group = find_by(name: 'System User Group', system: true)
    return group if group.present?

    group = create(name: 'System User Group', system: true)
    group.add(User.system_user)
    group
  end

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(
      arel_table[:name].matches(query).
      or(arel_table[:description].matches(query)),
    )
  end

  def add(users)
    # Force individual queries for paper_trail
    Array.wrap(users).uniq.each do |user|
      user = user_group_members.with_deleted.where(user_id: user.id).first_or_create!
      user.restore if user.deleted?

      # Queue recomputation of external report access
      user.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
    end
  end

  def remove(users)
    # Force individual queries for paper_trail
    Array.wrap(users).uniq.each do |user|
      user_group_members.find_by(user_id: user.id)&.destroy
      # Queue recomputation of external report access
      user.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
    end
  end

  def self.options_for_select(include_system: false)
    return order(name: :asc).pluck(:name, :id) if include_system

    not_system.order(name: :asc).pluck(:name, :id)
  end
end
