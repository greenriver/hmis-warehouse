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
  belongs_to :user_group, inverse_of: :access_controls
  has_many :users, through: :user_group

  delegate :health?, to: :role

  # These should not show up anywhere, (there should only be one)
  # The system access control list is joined to the hidden system group that includes
  # all data sources, reports, cohorts, and project groups
  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    joins(:access_group).merge(AccessGroup.hidden)
  end

  scope :not_system, -> do
    joins(:access_group).merge(AccessGroup.not_system)
  end

  scope :selectable, -> do
    not_system
  end

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

  def name
    "#{role.name} x #{access_group.name} x #{user_group.name}"
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
