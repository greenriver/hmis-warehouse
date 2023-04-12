###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # A proposed fulfillment of a referral request
  class ReferralPosting < HmisExternalApisBase
    self.table_name = 'hmis_external_referral_postings'
    belongs_to :referral, class_name: 'HmisExternalApis::Referral'
    belongs_to :referral_request, class_name: 'HmisExternalApis::ReferralRequest'

    # https://docs.google.com/spreadsheets/d/12wRLTjNdcs7A_1lHwkLUoKz1YWYkfaQs/edit#gid=26094550
    enum(
      status: {
        assigned_status: 12,
        closed_status: 13,
        accepted_pending_status: 18,
        denied_pending_status: 19,
        accepted_status: 20,
        denied_status: 21,
        accepted_by_other_program_status: 22,
        not_selected_status: 23,
        void_status: 25,
        new_status: 55,
        assigned_to_other_program_status: 60,
        # closed: 65,
      },
    )
  end
end
