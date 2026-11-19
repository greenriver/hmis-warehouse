###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared by the unauthenticated logo endpoints
module ControllerThemeLogoBehavior
  extend ActiveSupport::Concern

  LOGO_CONTENT_SECURITY_POLICY = "default-src 'none'; style-src 'unsafe-inline'; img-src data:; sandbox"

  class_methods do
    def memory_cache
      @memory_cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end

  # Responds 404 for a missing logo or one whose stored type is not an allowed image type.
  # The type check runs before stale? so a cached non-image blob never gets a 304.
  private def show_logo
    file = GrdaWarehouse::Theme.logo_for_type(params[:logo])
    return head :not_found unless GrdaWarehouse::Theme.allowed_logo?(file)

    response.headers['Content-Security-Policy'] = LOGO_CONTENT_SECURITY_POLICY
    blob = file.blob
    return unless stale?(etag: blob.checksum, last_modified: blob.created_at, public: true)

    data = self.class.memory_cache.fetch(blob.checksum, expires_in: 24.hours) do
      file.download
    end
    send_data(data, type: blob.content_type, filename: blob.filename.to_s, disposition: 'inline')
  end
end
