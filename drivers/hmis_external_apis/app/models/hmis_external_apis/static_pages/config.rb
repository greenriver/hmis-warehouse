###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::StaticPages
  Config = Struct.new(:site_title, :site_logo_url, :site_logo_dimensions, :recaptcha_key, :presign_url, keyword_init: true) do
    def js_config
      {
        recaptchaKey: recaptcha_key,
        presignUrl: presign_url,
      }
    end

    def csp_content
      [
        "default-src 'self'",
        "script-src 'unsafe-inline' cdn.jsdelivr.net www.google.com code.jquery.com www.gstatic.com",
        "style-src 'unsafe-inline' cdn.jsdelivr.net",
        "font-src 'self' fonts.gstatic.com",
        "img-src www.gstatic.com ahomewithhope.org",
        "frame-src www.google.com",
      ].join('; ')
    end
  end
end
