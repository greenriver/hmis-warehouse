###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module UserDirectoryReport::WarehouseReports
  class UsersController < ApplicationController
    helper_method :nav_link_classes
    helper_method :cas_available?

    def readonly?
      true
    end

    def warehouse
      @users = _users(User)
      @pagy, @users = pagy(@users)
      @user_source = 'warehouse'
      render :report
    end

    def cas
      if cas_available?
        @users = _users(Cas::User)
      else
        @users = []
      end
      @pagy, @users = pagy(@users)
      @user_source = 'cas'
      render :report
    end

    def nav_link_classes(link_type, user_source)
      class_list = ['nav-link']
      class_list.append('active') if link_type == user_source
      class_list.join(' ')
    end

    def cas_available?
      CasBase.db_exists? && Cas::User.take.respond_to?('exclude_from_directory')
    end

    private def _users(user_model)
      if params[:q].present?
        users = user_model.in_directory.
          text_search(params[:q]).
          order(:last_name, :first_name)
      else
        users = user_model.in_directory.
          order(:last_name, :first_name)
      end
      return users
    end
  end
end
