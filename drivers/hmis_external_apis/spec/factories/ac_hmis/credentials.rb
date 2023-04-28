###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  FactoryBot.define do
    factory :ac_hmis_mper_credential, parent: :grda_remote_oauth_credential, class: HmisExternalApis::AcHmis::MperCredential
    factory :ac_hmis_mci_credential, parent: :grda_remote_oauth_credential, class: HmisExternalApis::AcHmis::MciCredential
  end

end
