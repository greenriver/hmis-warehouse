###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :accountable_care_organization, class: 'Health::AccountableCareOrganization' do
    name { 'Example ACO' }
    short_name { 'ACO' }
    edi_name { 'EXAMPLE ACO' }
    vpr_name { 'ACO Example' }
    e_d_file_prefix { 'EX_ACO' }
    e_d_receiver_text { 'Example ACO Receiver' }
  end
end
