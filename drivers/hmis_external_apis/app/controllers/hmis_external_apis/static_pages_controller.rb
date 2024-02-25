###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisExternalApis::StaticPagesController < ActionController::Base
  include ::HmisExternalApis::StaticPagesHelper

  layout 'hmis_external_apis/static_pages'
  # these pages have inline csp meta tags
  content_security_policy false

  def show
    # this is intended for development. See PublishStaticFormsJob for production usage
    raise unless Rails.env.development?

    @field_collection = []
    template = "hmis_external_apis/static_pages/" + params[:template]
    render template: template
  end
end
