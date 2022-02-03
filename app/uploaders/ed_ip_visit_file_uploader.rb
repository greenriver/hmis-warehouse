###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# encoding: utf-8

class EdIpVisitFileUploader < CarrierWave::Uploader::Base
  # we will use mini magics API to process attachments
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  if ENV['S3_TMP_ACCESS_KEY_SECRET'].present?
    storage :aws
  else
    storage :file
  end

  # Override the directory where uploaded files will be stored.
  def store_dir
    "#{Rails.root}/tmp/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    "#{Rails.root}/tmp/uploads-cache/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  process :extract_file_metadata!

  # NOTE if you make changes here it would be a good idea to update test/uploaders/attachment_uploader_test.rb
  WHITELIST = IceNine.deep_freeze(['text/csv'])

  MANIPULATEABLE = IceNine.deep_freeze(
    [
      'image/jpeg',
      'image/png',
      'image/gif',
    ],
  )

  # normal content_type handling uses this
  # this is mostly to provide user feedback if they send
  # a content_type value with the upload
  def content_type_whitelist
    WHITELIST + ['application/octet-stream']
  end

  # MagicMimeWhitelist content_type handling uses
  # this list (Regexp actually is what they want)
  # this is checked against the actual uploaded data bytes
  # so a client cannot lie about the bytes sent
  # this should be very restrictive and is what we use to
  # decided what processing we are willing to try running
  def whitelist_mime_type_pattern
    Regexp.union WHITELIST
  end

  # Extracts the file metadata into the model fields
  # size and mime_type are forced to the
  # actual data, name defaults to thethe original_filename
  # if its not already set in the model
  def extract_file_metadata!
    model.name ||= file&.filename
    model.size = file&.size
    model.content_type = content_type_from_bytes(file) # use magic for this and NOT ruby's built in lookup
  end

  private def content_type_from_bytes(_file_to_test = file)
    @filemagic ||= FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
    begin
      @filemagic.buffer(file.read)
    rescue StandardError
      nil
    end
  end

  alias extract_content_type content_type_from_bytes

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_white_list
    ['.*']
  end

  # Provide a range of file sizes which are allowed to be uploaded
  # NOT WORKING
  def size_range
    0..25.megabytes # Up to two megabytes
  end

  def max_size_in_bytes
    size_range.last
  end

  def max_size_in_mb
    (max_size_in_bytes / 1024 / 1024).round
  end
  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
