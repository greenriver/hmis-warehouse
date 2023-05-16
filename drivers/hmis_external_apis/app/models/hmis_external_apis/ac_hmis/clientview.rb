###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# To create a ClientView URL:
# GrdaWarehouse::RemoteCredentials::ExternalLink.create!(
# 	slug: HmisExternalApis::AcHmis::Clientview::SYSTEM_ID,
# 	endpoint: 'https://www.google.com', # URL base of ClientView
# 	username: '',
# 	encrypted_password: '',
# 	active: true,
# )
# )
module HmisExternalApis::AcHmis
  class Clientview
    SYSTEM_ID = 'ac_hmis_clientview'.freeze

    # @return [String, nil]
    def self.link_base
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first&.endpoint
    end
  end
end
