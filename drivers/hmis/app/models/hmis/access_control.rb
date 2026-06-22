###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# HMIS uses similar but separate permissions system from the warehouse
# See drivers/hmis/doc/PERMISSIONS.md

class Hmis::AccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_group, class_name: '::Hmis::AccessGroup'
  belongs_to :role, class_name: 'Hmis::Role'
  belongs_to :user_group, class_name: '::Hmis::UserGroup', required: false, inverse_of: :access_controls
  has_many :users, through: :user_group
  has_many :user_access_controls, class_name: 'Hmis::UserAccessControl', inverse_of: :access_control, dependent: :destroy

  def entity_name
    "#{role&.name || 'missing role'} x #{access_group&.name || 'missing collection'} x #{user_group&.name || 'missing user group'}"
  end

  def self.describe_changes(version, changes, excluded_fields = [])
    case version.event
    when 'create'
      ['Created access control']
    when 'destroy'
      ['Deleted access control']
    else
      filtered = (changes || {}).reject { |field, _| excluded_fields.include?(field.to_s) }
      filtered.map do |field, (from_id, to_id)|
        from_name = resolve_fk_name(field, from_id)
        to_name = resolve_fk_name(field, to_id)
        "Changed #{field.humanize.titleize}: from #{from_name} to #{to_name}"
      end.presence || ['Updated access control']
    end
  end

  def self.resolve_fk_name(field, id)
    return 'none' if id.nil?

    klass = case field.to_s
    when 'role_id' then Hmis::Role
    when 'user_group_id' then Hmis::UserGroup
    when 'access_group_id' then Hmis::AccessGroup
    end
    klass ? (klass.with_deleted.find_by(id: id)&.name || "ID #{id}") : id.to_s
  end
  private_class_method :resolve_fk_name

  scope :ordered, -> do
    joins(:user_group, :role, :access_group).
      order(
        Hmis::UserGroup.arel_table[:name].lower.asc,
        Hmis::Role.arel_table[:name].lower.asc,
        Hmis::AccessGroup.arel_table[:name].lower.asc,
      )
  end

  # filter for access controls that somehow interact with the following
  # User, UserGroup, Role, AccessGroup
  scope :filtered, ->(filter_params) do
    return current_scope unless filter_params
    return current_scope if filter_params[:user_id].blank? && filter_params[:user_group_id].blank? && filter_params[:role_id].blank? && filter_params[:access_group_id].blank?

    ids = []
    if filter_params[:user_id].present?
      user_scope = Hmis::UserGroup.with_user_id(filter_params[:user_id].to_i)
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
    if filter_params[:access_group_id].present?
      entity_group_scope = where(access_group_id: filter_params[:access_group_id].to_i)
      ids += entity_group_scope.pluck(:id)
    end

    where(id: ids)
  end
end
