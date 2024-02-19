###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class StaticPagesController < ActionController::Base
  layout 'static_pages'
  # these pages have inline csp meta tags
  content_security_policy false

  def show
    case params[:id]
    when 'tchc_helpline'
      @config = tchc_config
      render 'tchc_helpline'
    when 'tchc_prevention_screening'
      @config = tchc_config
      render 'tchc_prevention_screening'
    else
      head :not_found
    end
  end

  protected

  def tchc_config
    StaticPages::Config.new(
      site_title: 'Tarrant County Homeless Coalition',
      site_logo_url: 'https://ahomewithhope.org/wp-content/themes/tchc/assets/images/logo.png',
      site_logo_dimensions: [110, 60],
    )
  end
end
