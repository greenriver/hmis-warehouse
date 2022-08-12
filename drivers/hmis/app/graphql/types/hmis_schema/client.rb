###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Client < Types::BaseObject
    include Types::HmisSchema::HasEnrollments

    description 'HUD Client'
    field :id, ID, null: false
    field :personal_id, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :preferred_name, String, null: true
    field :name_suffix, String, null: true
    field :ssn_serial, String, null: true
    field :dob, GraphQL::Types::ISO8601Date, 'Date of birth as format yyyy-mm-dd', null: true
    field :pronouns, String, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    enrollments_field :enrollments, type: Types::HmisSchema::Enrollment.page_type

    def enrollments
      resolve_enrollments
    end
  end
end
