###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class RootController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    # custom_content = lookup_context.exists?('homepage_content', ['root'], true)
    return unless current_user

    already_there = current_user.my_root_path == root_path
    redirect_to current_user.my_root_path unless already_there
  end

  private def resource_name
    :user
  end
  helper_method :resource_name

  private def resource_class
    User
  end
  helper_method :resource_class

  def resource
    @user = User.new
  end
  helper_method :resource

  def devise_mapping
    @devise_mapping ||= Devise.mappings[resource_name]
  end
  helper_method :devise_mapping
end
