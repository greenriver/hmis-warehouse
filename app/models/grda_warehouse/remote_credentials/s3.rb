###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'uri'
require 'net/http'
module GrdaWarehouse
  class RemoteCredentials::S3 < GrdaWarehouse::RemoteCredential
    alias_attribute :s3_access_key_id, :username
    alias_attribute :s3_secret_access_key, :password
    alias_attribute :s3_prefix, :path

    def s3
      @s3 ||= if s3_secret_access_key.present? && s3_secret_access_key != 'unknown'
        AwsS3.new(
          region: region,
          bucket_name: bucket,
          access_key_id: s3_access_key_id,
          secret_access_key: s3_secret_access_key,
        )
      else
        AwsS3.new(
          region: region,
          bucket_name: bucket,
        )
      end
    end
  end
end
