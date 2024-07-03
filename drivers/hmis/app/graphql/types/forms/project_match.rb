#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class Forms::ProjectMatch < Types::BaseObject
    # object is a Hmis::Form::InstanceProjectMatch
    graphql_name 'FormProjectMatch'
    skip_activity_log
    description 'Project match for a form, including information about which clients in this project the form is applicable to.'

    field :id, ID, null: false
    field :project_name, String, null: false
    field :organization_name, String, null: false
    field :data_collected_about, Types::Forms::Enums::DataCollectedAbout, null: false

    def id
      object.project.id
    end

    def project_name
      object.project.project_name
    end

    def organization_name
      object.project.organization.organization_name
    end

    def data_collected_about
      object.instance.data_collected_about || 'ALL_CLIENTS'
    end
  end
end
