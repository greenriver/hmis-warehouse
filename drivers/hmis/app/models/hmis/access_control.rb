###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_group, class_name: '::Hmis::AccessGroup'
  belongs_to :role, class_name: 'Hmis::Role'
  belongs_to :user_group, class_name: '::Hmis::UserGroup', required: false, inverse_of: :access_controls
  has_many :users, through: :user_group

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
    return current_scope if filter_params[:user_id].blank? && filter_params[:user_group_id].blank? && filter_params[:role_id].blank? && filter_params[:collection_id].blank?

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
