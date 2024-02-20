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
    case params[:id]
    when 'tchc_helpline'
      render 'tchc_helpline'
    when 'tchc_prevention_screening'
      render 'tchc_prevention_screening'
    else
      head :not_found
    end
  end
end
