###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteConfig < GrdaWarehouseBase
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]
    # Be nice to S3
    alias_attribute :s3_access_key_id, :username
    alias_attribute :s3_secret_access_key, :password

    # The following should be implemented in the concrete classes
    def connect
      raise NoMethodError
    end

    def get(_path)
      raise NoMethodError
    end

    def put(_path, _file)
      raise NoMethodError
    end

    def list(_path)
      raise NoMethodError
    end

    def rm(_path)
      raise NoMethodError
    end
  end
end
