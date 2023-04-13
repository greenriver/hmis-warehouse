###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteCredential < GrdaWarehouseBase
    acts_as_paranoid
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]
    has_many :external_ids,
      class_name: 'HmisExternalApis::ExternalId',
      foreign_key: :remote_credential_id,
      dependent: :restrict_with_exception

    scope :active, -> do
      where(active: true)
    end

    def self.mci
      where(slug: 'mci').first!
    end

    def self.mper
      where(slug: 'mper').first!
    end

  end
end
