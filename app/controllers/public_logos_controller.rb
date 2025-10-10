###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class PublicLogosController < ApplicationController
  skip_before_action :authenticate_user!
  def show
    file = GrdaWarehouse::Theme.logo_for_type(params[:logo])
    return head :not_found unless file.attached?

    blob = file.blob

    return unless stale?(etag: blob.checksum, last_modified: blob.created_at, public: true)

    data = self.class.memory_cache.fetch("public_logo_#{blob.checksum}", expires_in: 24.hours) do
      file.download
    end
    send_data(data, type: blob.content_type, filename: blob.filename.to_s, disposition: 'inline')
  end

  def self.memory_cache
    @memory_cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end
