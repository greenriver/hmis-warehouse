###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisExternalApis::TcHmis::StaticPagesController < ActionController::Base
  include ::HmisExternalApis::TcHmis::StaticPagesHelper

  layout 'hmis_external_apis/static_pages'
  # these pages have inline csp meta tags
  content_security_policy false

  def show
    # this is intended for development. See PublishStaticFormsJob for production usage
    raise unless Rails.env.development?

    @field_collection = []
    # template might be tchc_helpline or tchc_prevention_screening
    template = params[:id]
    render template
  end
end
