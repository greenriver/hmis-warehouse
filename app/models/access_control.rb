###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccessControl < ApplicationRecord
  include ActionView::Helpers::TagHelper
  include UserPermissionCache

  acts_as_paranoid
  has_paper_trail

  after_save :invalidate_user_permission_cache

  belongs_to :access_group
  belongs_to :role
  belongs_to :user_group, inverse_of: :access_controls
  has_many :users, through: :user_group

  delegate :health?, to: :role
  validates_presence_of :access_group_id, :role_id, :user_group_id

  # These should not show up anywhere, (there should only be one)
  # The system access control list is joined to the hidden system group that includes
  # all data sources, reports, cohorts, and project groups
  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    joins(:access_group).merge(AccessGroup.hidden)
  end

  scope :not_system, -> do
    joins(:access_group).
      merge(AccessGroup.not_system)
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
    joins(:role, :access_group, :user_group).
      order(UserGroup.arel_table[:name].asc, Role.arel_table[:name].asc, AccessGroup.arel_table[:name].asc)
  end

  # filter for access controls that somehow interact with the following
  # User, UserGroup, Role, EntityGroup
  scope :filtered, ->(filter_params) do
    return current_scope unless filter_params

    user_scope = current_scope
    user_group_scope = current_scope
    role_scope = current_scope
    entity_group_scope = current_scope

    user_scope = UserGroup.with_user_id(filter_params[:user_id].to_i) if filter_params[:user_id].present?
    user_group_scope = where(user_group_id: filter_params[:user_group_id].to_i) if filter_params[:user_group_id].present?
    role_scope = where(role_id: filter_params[:role_id].to_i) if filter_params[:role_id].present?
    entity_group_scope = where(access_group_id: filter_params[:access_group_id].to_i) if filter_params[:access_group_id].present?

    ids = joins(:user_group).
      merge(user_scope).
      merge(user_group_scope).
      merge(role_scope).
      merge(entity_group_scope).pluck(:id)
    where(id: ids)
  end

  # If all entities are system entities, this is a system Access Control
  def system?
    [user_group.system?, role.system?, access_group.system?].all?
  end

  # Delegate add and remove to the user group
  def add(users)
    user_group.add(users)
  end

  def remove(users)
    user_group.remove(users)
  end

  def name
    "#{role.name} x #{access_group.name} x #{user_group.name}"
  end

  def name_as_html
    name_parts = [
      content_tag(:span, role.name, class: 'badge badge-info font-weight-normal'),
      content_tag(:span, access_group.name, class: 'badge badge-info font-weight-normal'),
      content_tag(:span, user_group.name, class: 'badge badge-info font-weight-normal'),
    ]

    content_tag(
      :div,
      name_parts.join(' ').html_safe,
      class: 'font-size-md',
    ).html_safe
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
