###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Defines the `filtered` scope used by the warehouse and HMIS access control admin pages.
# Every present filter must match. The collection class must respond to
# `contains_with_inherited(entity)` and `contains_coc_code_with_inherited(coc_code)`.
module AccessControlFiltering
  extend ActiveSupport::Concern

  class_methods do
    def filterable_by(collection_association:, entity_class_names:)
      scope :filtered, ->(filter_params) do
        return all if filter_params.blank?

        collection_reflection = reflect_on_association(collection_association)
        collection_key = collection_reflection.foreign_key.to_sym
        collection_class = collection_reflection.klass
        user_group_class = reflect_on_association(:user_group).klass

        scope = all
        scope = scope.where(user_group_id: user_group_class.with_user_id(filter_params[:user_id].to_i).select(:id)) if filter_params[:user_id].present?
        scope = scope.where(user_group_id: filter_params[:user_group_id].to_i) if filter_params[:user_group_id].present?
        scope = scope.where(role_id: filter_params[:role_id].to_i) if filter_params[:role_id].present?
        scope = scope.where(collection_key => filter_params[collection_key].to_i) if filter_params[collection_key].present?
        entity_class_names.each do |key, class_name|
          next if filter_params[key].blank?

          entity = class_name.constantize.find_by(id: filter_params[key].to_i)
          scope = entity ? scope.where(collection_key => collection_class.contains_with_inherited(entity).select(:id)) : scope.none
        end
        scope = scope.where(collection_key => collection_class.contains_coc_code_with_inherited(filter_params[:coc_code]).select(:id)) if filter_params[:coc_code].present?
        scope
      end
    end
  end
end
