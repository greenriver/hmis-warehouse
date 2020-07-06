###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# encoding: utf-8

class DocumentExportUploader < CarrierWave::Uploader::Base
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

  WHITELIST = ['application/pdf'].freeze

  def content_type_whitelist
    WHITELIST
  end
end
