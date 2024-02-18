module StaticPages
  Config = Struct.new(:site_title, :site_logo_url, :site_logo_dimensions, :google_captcha_key, keyword_init: true) do
    def form_id
      'main-form'
    end

    def csp_content
      [
        "default-src 'self'",
        "script-src 'https://cdn.jsdelivr.net'",
        "style-src 'https://cdn.jsdelivr.net'",
        "font-src 'self' 'https://fonts.gstatic.com'"
      ].join("; ")
    end
  end
end
