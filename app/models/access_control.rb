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

  delegate :health?, to: :role

  scope :health, -> do
    joins(:role).merge(Role.health)
  end

  scope :homeless, -> do
    joins(:role).merge(Role.editable)
  end

  scope :nurse_care_manager, -> do
    joins(:role).merge(Role.nurse_care_manager)
  end

  scope :ordered, -> do
    joins(:role, :access_group).
      order(Role.arel_table[:name].asc, AccessGroup.arel_table[:name].asc)
  end

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

  def self.options_for_select(include_health: true, include_homeless: true)
    {}.tap do |options|
      scope = if include_health && include_homeless
        all
      elsif include_health
        health
      elsif include_homeless
        homeless
      else
        none
      end

      scope.ordered.each do |control|
        options[control.role.name] ||= []
        options[control.role.name] << [control.name, control.id]
      end
    end
  end
end
