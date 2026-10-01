###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# DO NOT EDIT! The original is at:
# https://github.com/greenriver/gr-catalog/tree/main/catalog/team/npo/shared/shared_files
# This file is shared across all projects; ignore project-specific RuboCop rules
# rubocop:disable all

require 'roda'

class MetricsApp < Roda
  route do |r|
    r.get 'healthz' do
      'ok'
    end

    r.get 'bootz' do
      if File.exist?(DjMetrics::Plugin::FILENAME)
        'ok'
      else
        response.status = 404
        'error'
      end
    end

    # Catch-all route to redirect to /metrics
    r.get true do
      r.redirect '/metrics'
    end
  end
end
