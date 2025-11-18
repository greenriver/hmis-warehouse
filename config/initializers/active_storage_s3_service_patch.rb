###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Patch to fix deprecation warning for ActiveStorage S3Service
# ActiveStorage 7.2.2.2 uses deprecated Aws::S3::Object#upload_stream method
# This patch replaces it with Aws::S3::TransferManager#upload_stream
# The deprecated upload_stream method is addressed in rails 8.0.3
Rails.application.config.to_prepare do
  # Ensure ActiveStorage S3Service is loaded before patching
  require 'active_storage/service/s3_service' if defined?(ActiveStorage)

  # Only patch if S3Service is available (requires aws-sdk-s3 gem)
  if defined?(ActiveStorage::Service::S3Service)
    ActiveStorage::Service::S3Service.class_eval do
      # Override compose to use TransferManager instead of deprecated upload_stream
      def compose(source_keys, destination_key, filename: nil, content_type: nil, disposition: nil, custom_metadata: {})
        content_disposition = content_disposition_with(type: disposition, filename: filename) if disposition && filename

        transfer_manager.upload_stream(
          bucket: bucket.name,
          key: destination_key,
          content_type: content_type,
          content_disposition: content_disposition,
          part_size: self.class::MINIMUM_UPLOAD_PART_SIZE,
          metadata: custom_metadata,
          **upload_options
        ) do |write_stream|
          source_keys.each do |source_key|
            stream(source_key) do |chunk|
              IO.copy_stream(StringIO.new(chunk), write_stream)
            end
          end
        end
      end

      private

      # Override upload_with_multipart to use TransferManager instead of deprecated upload_stream
      def upload_with_multipart(key, io, content_type: nil, content_disposition: nil, custom_metadata: {})
        part_size = [io.size.fdiv(self.class::MAXIMUM_UPLOAD_PARTS_COUNT).ceil, self.class::MINIMUM_UPLOAD_PART_SIZE].max

        transfer_manager.upload_stream(
          bucket: bucket.name,
          key: key,
          content_type: content_type,
          content_disposition: content_disposition,
          part_size: part_size,
          metadata: custom_metadata,
          **upload_options
        ) do |write_stream|
          IO.copy_stream(io, write_stream)
        end
      end

      # Create a TransferManager instance using the S3 client
      def transfer_manager
        @transfer_manager ||= Aws::S3::TransferManager.new(client: client.client)
      end
    end
  end
end

