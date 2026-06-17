###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Talentlms
  class Login < GrdaWarehouseBase
    self.table_name = :talentlms_logins

    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]
    belongs_to :user
    belongs_to :config, class_name: 'Talentlms::Config'
    has_many :trainings, class_name: 'Talentlms::CompletedTraining'
  end
end
