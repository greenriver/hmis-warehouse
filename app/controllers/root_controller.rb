###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class RootController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    custom_content = lookup_context.exists?('homepage_content', ['root'], true)
    redirect_to clients_path if current_user&.can_access_some_client_search? && ! custom_content
  end
end
