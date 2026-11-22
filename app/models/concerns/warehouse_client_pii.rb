###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# PII columns that exist only on the warehouse Client table, shared by its warehouse and HMIS models
module WarehouseClientPii
  extend ActiveSupport::Concern

  include HasPiiAttributes

  included do
    pii_attr :encrypted_FirstName, as: :first_name
    pii_attr :encrypted_MiddleName, as: :middle_name
    pii_attr :encrypted_LastName, as: :last_name
    pii_attr :encrypted_SSN, as: :ssn
    pii_attr :rrh_assessment_contact_info, as: :free_text
  end
end
