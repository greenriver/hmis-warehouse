###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
end
