###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class Clientview
    SYSTEM_ID = 'ac_hmis_clientview'.freeze

    # @return [String, nil]
    def self.link_base
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first&.link_base
    end
  end
end
