###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# AccessControl is part of the "new" ACL permissions model
#
# An AccessControl includes:
# * A role that specifies the set of permissions controlling what actions a user can perform within the system
# * A user-group which defines the users who are granted those permissions
# * A collection which defines the set of entities to which the permissions are applied (Project, Organization, etc)
#
class AccessControl < ApplicationRecord
  include ActionView::Helpers::TagHelper
  include UserPermissionCache

  acts_as_paranoid
  has_paper_trail

  after_save :invalidate_user_permission_cache

  belongs_to :collection
  belongs_to :role
  belongs_to :user_group, inverse_of: :access_controls
  has_many :users, through: :user_group

  delegate :health?, to: :role
  validates_presence_of :collection_id, :role_id, :user_group_id

  # These should not show up anywhere, (there should only be one)
  # The system access control list is joined to the hidden system group that includes
  # all data sources, reports, cohorts, and project groups
  # hide previous declaration of :system (from Kernel), we'll use this one
  replace_scope :system, -> do
    joins(:collection).merge(Collection.hidden)
  end

  scope :not_system, -> do
    joins(:collection).
      merge(Collection.not_system)
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
    joins(:role, :collection, :user_group).
      order(UserGroup.arel_table[:name].asc, Role.arel_table[:name].asc, Collection.arel_table[:name].asc)
  end

  # filter for access controls that somehow interact with the following
  # User, UserGroup, Role, EntityGroup
  scope :filtered, ->(filter_params) do
    return current_scope unless filter_params
    return current_scope if filter_params[:user_id].blank? && filter_params[:user_group_id].blank? && filter_params[:role_id].blank? && filter_params[:collection_id].blank?

    ids = []
    if filter_params[:user_id].present?
      user_scope = UserGroup.with_user_id(filter_params[:user_id].to_i)
      ids += joins(:user_group).
        merge(user_scope).pluck(:id)
    end
    if filter_params[:user_group_id].present?
      user_group_scope = where(user_group_id: filter_params[:user_group_id].to_i)
      ids += user_group_scope.pluck(:id)
    end
    if filter_params[:role_id].present?
      role_scope = where(role_id: filter_params[:role_id].to_i)
      ids += role_scope.pluck(:id)
    end
    if filter_params[:collection_id].present?
      entity_group_scope = where(collection_id: filter_params[:collection_id].to_i)
      ids += entity_group_scope.pluck(:id)
    end

    where(id: ids)
  end

  # If all entities are system entities, this is a system Access Control
  def system?
    [user_group.system?, role.system?, collection.system?].all?
  end

  def name
    "#{role.name} x #{collection.name} x #{user_group.name}"
  end

  def name_as_html
    name_parts = [
      content_tag(:span, role.name, class: 'badge badge-info font-weight-normal'),
      content_tag(:span, collection.name, class: 'badge badge-info font-weight-normal'),
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
