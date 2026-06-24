###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthPctp
  class SignatureFile < ::Health::HealthFile
    belongs_to :careplan, class_name: 'HealthPctp::Careplan', foreign_key: :parent_id, optional: true
  end
end
