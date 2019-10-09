###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class RootController < ApplicationController
  skip_before_action :authenticate_user!
  def index; end
end
