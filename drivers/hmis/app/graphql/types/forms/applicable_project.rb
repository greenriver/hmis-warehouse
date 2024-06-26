#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class Forms::ApplicableProject < Types::BaseObject
    skip_activity_log
    description 'Applicable project for a form, including information about which clients in this project the form is applicable to.'

    field :id, ID, null: false
    field :project_name, String, null: false
    field :organization_name, String, null: false

    # todo @martha - applicability rule

    def organization_name
      object.organization.organization_name
    end
  end
end
