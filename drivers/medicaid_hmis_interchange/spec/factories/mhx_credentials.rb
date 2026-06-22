###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :mhx_sftp_credentials, class: 'Health::ImportConfigPassword' do
    host { 'sftp' }
    path { '/sftp' }
    username { 'user' }
    password { 'password' }
    kind { 'medicaid_hmis_exchange' }
    data_source_name { 'example@example.com' }
  end
end
