###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Theme
  # Exposes theme logos to the IdP login screens. Currently just serves the same logo
  # as PublicLogosController regardless of the requested type; kept as its own controller
  # so we can later serve a distinct logo for the warehouse vs. HMIS IdP without touching
  # the public-facing route.
  class LogoController < ApplicationController
    skip_before_action :authenticate_user!

    def show
      file = GrdaWarehouse::Theme.logo_for_type(params[:logo])
      return head :not_found unless file.attached?

      blob = file.blob

      return unless stale?(etag: blob.checksum, last_modified: blob.created_at, public: true)

      data = self.class.memory_cache.fetch("theme_logo_#{blob.checksum}", expires_in: 24.hours) do
        file.download
      end
      send_data(data, type: blob.content_type, filename: blob.filename.to_s, disposition: 'inline')
    end

    def self.memory_cache
      @memory_cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end
end
