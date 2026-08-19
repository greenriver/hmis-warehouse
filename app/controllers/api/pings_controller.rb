###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Monitoring endpoint. Deliberately authenticated rather than public, so an
# unauthenticated probe can't report healthy.
module Api
  class PingsController < ApplicationController
    def show
      head :ok
    end

    # rescue prevents the error from bubbling; 500's are expected to be generated
    # by monitoring
    rescue_from 'Idp::UnauthenticatedRequestError' do |_exception|
      head :internal_server_error
    end
  end
end
