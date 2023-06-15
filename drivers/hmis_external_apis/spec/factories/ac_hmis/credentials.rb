###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  FactoryBot.define do
    factory :ac_hmis_mper_credential, parent: :grda_remote_oauth_credential do
      slug { 'ac_hmis_mper' }
    end
    factory :ac_hmis_mci_credential, parent: :grda_remote_oauth_credential do
      slug { 'ac_hmis_mci' }
    end
    factory :ac_hmis_warehouse_credential, parent: :grda_remote_oauth_credential do
      slug { HmisExternalApis::AcHmis::DataWarehouseApi::SYSTEM_ID }
    end
    factory :ac_hmis_link_credential, parent: :grda_remote_oauth_credential do
      slug { 'ac_hmis_link' }
    end
  end
end
