# frozen_string_literal: true

require 'roda'

class App < Roda
  route do |r|
    # Route for health check
    r.get 'healthz' do
      'ok'
    end

    # Catch-all route to redirect to /metrics
    r.get true do
      r.redirect '/metrics'
    end
  end
end
