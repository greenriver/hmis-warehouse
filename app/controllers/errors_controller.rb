###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  def not_found
    render status: 404
  end

  def unacceptable
    render status: 422
  end

  def internal_error
    render status: 500
  end
end
