# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data, 'https://fonts.gstatic.com'
  policy.img_src     :self, :data, 'https://tile.openstreetmap.org'
  policy.object_src  :none
  policy.script_src  :self, 'https://cdnjs.cloudflare.com/ajax/libs/chance/1.0.4/chance.min.js', 'https://unpkg.com/ag-grid-community@27.3.0/dist/ag-grid-community.min.noStyle.js', :unsafe_inline, :unsafe_eval
  policy.style_src   :self, 'https://fonts.googleapis.com', 'https://unpkg.com/ag-grid-community@27.3.0/dist/styles/ag-grid.css', 'https://unpkg.com/ag-grid-community@27.3.0/dist/styles/ag-theme-balham.css', :unsafe_inline
  policy.report_uri '/csp-violation-report-endpoint' # Placeholder so report only policy will work

  # If you are using webpack-dev-server then specify webpack-dev-server host
  # policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Initially run in report-only mode to be safe.
# if true # Rails.env.development? || Rails.env.test?
Rails.application.config.content_security_policy_report_only = true
# end
