###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class SignatureFile < ::Health::HealthFile
    acts_as_paranoid

    belongs_to :careplan, class_name: 'HealthPctp::Careplan', foreign_key: :parent_id, optional: true
  end
end
