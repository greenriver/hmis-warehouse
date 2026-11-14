###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # STI base class
  class RemoteCredential < GrdaWarehouseBase
    acts_as_paranoid
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    scope :active, -> do
      where(active: true)
    end

    def self.for_active_slug(slug)
      active.where(slug: slug).first
    end

    # Extensions from drivers — see docs/architecture/08-concepts/08-3-driver-module-pattern.md
    include HmisExternalApis::GrdaWarehouse::RemoteCredentialExtension
  end
end
