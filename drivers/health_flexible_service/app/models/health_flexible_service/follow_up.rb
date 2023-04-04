###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService
  class FollowUp < HealthBase
    acts_as_paranoid

    # belongs_to :patient, class_name: 'Health::Patient', optional: true
    belongs_to :user, class_name: 'User', optional: true
    belongs_to :vpr, inverse_of: :follow_ups

    scope :extension_requested, -> do
      where(additional_flex_services_requested: true)
    end

    def set_defaults
      client = vpr.client

      self.completed_on = Date.current
      self.first_name = client.FirstName
      self.middle_name = client.MiddleName
      self.last_name = client.LastName
      self.dob = client.patient&.birthdate.presence || client.DOB
      self.delivery_first_name = user.first_name
      self.delivery_last_name = user.last_name
      self.delivery_organization = user.agency&.name
      self.delivery_phone = user.phone
      self.delivery_email = user.email
      self.reviewer_first_name = user.first_name
      self.reviewer_last_name = user.last_name
      self.reviewer_organization = user.agency&.name
      self.reviewer_phone = user.phone
      self.reviewer_email = user.email
      self.agreement_to_flex_services = true
      self.aco_approved_flex_services = true
      self.aco_approved_flex_services_on = Date.current
    end
  end
end
