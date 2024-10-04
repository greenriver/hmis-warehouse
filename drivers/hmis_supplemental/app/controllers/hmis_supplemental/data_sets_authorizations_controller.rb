###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisSupplemental
  class DataSetAuthorizationsController < ApplicationController
    # FIXME: maybe additional permission needed?
    before_action :require_can_edit_users!

    def show
    end

    def update
      @data_set = load_data_set
      @data_set.attributes = data_set_params

      # TODO: save permissions
      raise 'tbd'
    end

    protected

    def load_data_set
      data_set_scope.find(params[:id])
    end

    def data_set_scope
      HmisSupplemental::DataSet.viewable_by(current_user)
    end

    def data_set_params
      params.require(:data_set).permit(
        :users,
        :editor_ids,
      )
    end

    before_action :assign_globals

    def assign_globals
      @data_set = load_data_set
      @editor_ids = @data_set.editable_access_control.user_ids
      # TODO: START_ACL remove when ACL transition complete
      @groups = @data_set.access_groups
      @group_ids = @data_set.access_group_ids
      # END_ACL
    end
  end
end
