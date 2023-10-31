###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:all) do
    cleanup_test_environment
  end

  let!(:client) { create(:hmis_hud_client_complete, data_source: ds1, user: u1) }
  let!(:project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: project, client: client, user: u1) }
  let!(:access_control) do
    create_access_control(hmis_user, project, with_permission: [:can_view_clients, :can_view_dob, :can_view_enrollment_details, :can_view_project])
  end

  before(:each) do
    hmis_login(user)
  end

  describe 'full enrollment details (for enrollment dashboard)' do
    let(:query) do
      <<~GRAPHQL
        query GetEnrollmentDetails($id: ID!) {
          enrollment(id: $id) {
            ...AllEnrollmentDetails
            __typename
          }
        }

        fragment AllEnrollmentDetails on Enrollment {
          ...EnrollmentFields
          ...EnrollmentOccurrencePointFields
          numUnitsAssignedToHousehold
          intakeAssessment {
            id
            __typename
          }
          exitAssessment {
            id
            __typename
          }
          customDataElements {
            ...CustomDataElementFields
            __typename
          }
          client {
            hudChronic
            ...ClientNameDobVet
            customDataElements {
              ...CustomDataElementFields
              __typename
            }
            access {
              ...ClientAccessFields
              __typename
            }
            __typename
          }
          openEnrollmentSummary {
            ...EnrollmentSummaryFields
            __typename
          }
          project {
            ...ProjectNameAndType
            ...ProjectCocCount
            hasUnits
            dataCollectionFeatures {
              ...DataCollectionFeatureFields
              __typename
            }
            occurrencePointForms {
              ...OccurrencePointFormFields
              __typename
            }
            access {
              ...ProjectAccessFields
              __typename
            }
            __typename
          }
          __typename
        }

        fragment EnrollmentFields on Enrollment {
          id
          lockVersion
          entryDate
          exitDate
          exitDestination
          project {
            ...ProjectNameAndType
            __typename
          }
          inProgress
          relationshipToHoH
          enrollmentCoc
          householdId
          householdShortId
          householdSize
          client {
            ...ClientNameDobVet
            __typename
          }
          access {
            ...EnrollmentAccessFields
            __typename
          }
          currentUnit {
            id
            name
            __typename
          }
          __typename
        }

        fragment ProjectNameAndType on Project {
          id
          projectName
          projectType
          __typename
        }

        fragment ClientNameDobVet on Client {
          ...ClientName
          dob
          veteranStatus
          __typename
        }

        fragment ClientName on Client {
          id
          lockVersion
          firstName
          middleName
          lastName
          nameSuffix
          __typename
        }

        fragment EnrollmentAccessFields on EnrollmentAccess {
          id
          canEditEnrollments
          canDeleteEnrollments
          __typename
        }

        fragment EnrollmentOccurrencePointFields on Enrollment {
          id
          lockVersion
          entryDate
          exitDate
          dateOfEngagement
          moveInDate
          livingSituation
          enrollmentCoc
          dateOfPathStatus
          clientEnrolledInPath
          reasonNotEnrolled
          disablingCondition
          translationNeeded
          preferredLanguage
          preferredLanguageDifferent
          __typename
        }

        fragment CustomDataElementFields on CustomDataElement {
          id
          key
          label
          fieldType
          repeats
          value {
            ...CustomDataElementValueFields
            __typename
          }
          values {
            ...CustomDataElementValueFields
            __typename
          }
          __typename
        }

        fragment CustomDataElementValueFields on CustomDataElementValue {
          id
          valueBoolean
          valueDate
          valueFloat
          valueInteger
          valueJson
          valueString
          valueText
          user {
            ...UserFields
            __typename
          }
          dateCreated
          dateUpdated
          __typename
        }

        fragment UserFields on User {
          __typename
          id
          name
        }

        fragment ClientAccessFields on ClientAccess {
          id
          canEditClient
          canDeleteClient
          canViewDob
          canViewFullSsn
          canViewPartialSsn
          canEditEnrollments
          canDeleteEnrollments
          canViewEnrollmentDetails
          canDeleteAssessments
          canManageAnyClientFiles
          canManageOwnClientFiles
          canViewAnyConfidentialClientFiles
          canViewAnyNonconfidentialClientFiles
          canAuditClients
          __typename
        }

        fragment EnrollmentSummaryFields on EnrollmentSummary {
          id
          entryDate
          inProgress
          moveInDate
          projectId
          projectName
          projectType
          canViewEnrollment
          __typename
        }

        fragment ProjectCocCount on Project {
          projectCocs {
            nodesCount
            __typename
          }
          __typename
        }

        fragment DataCollectionFeatureFields on DataCollectionFeature {
          id
          role
          dataCollectedAbout
          legacy
          __typename
        }

        fragment OccurrencePointFormFields on OccurrencePointForm {
          id
          dataCollectedAbout
          definition {
            ...FormDefinitionFields
            __typename
          }
          __typename
        }

        fragment FormDefinitionFields on FormDefinition {
          id
          role
          title
          cacheKey
          definition {
            ...FormDefinitionJsonFields
            __typename
          }
          __typename
        }

        fragment FormDefinitionJsonFields on FormDefinitionJson {
          item {
            ...ItemFields
            item {
              ...ItemFields
              item {
                ...ItemFields
                item {
                  ...ItemFields
                  item {
                    ...ItemFields
                    __typename
                  }
                  __typename
                }
                __typename
              }
              __typename
            }
            __typename
          }
          __typename
        }

        fragment ItemFields on FormItem {
          __typename
          linkId
          type
          component
          prefix
          text
          briefText
          readonlyText
          helperText
          required
          warnIfEmpty
          hidden
          readOnly
          repeats
          mapping {
            recordType
            fieldName
            customFieldKey
            __typename
          }
          pickListReference
          serviceDetailType
          size
          assessmentDate
          prefill
          bounds {
            id
            severity
            type
            question
            valueNumber
            valueDate
            valueLocalConstant
            offset
            __typename
          }
          pickListOptions {
            ...PickListOptionFields
            __typename
          }
          initial {
            valueCode
            valueBoolean
            valueNumber
            valueLocalConstant
            initialBehavior
            __typename
          }
          dataCollectedAbout
          disabledDisplay
          enableBehavior
          enableWhen {
            ...EnableWhenFields
            __typename
          }
          autofillValues {
            valueCode
            valueQuestion
            valueBoolean
            valueNumber
            sumQuestions
            autofillBehavior
            autofillReadonly
            autofillWhen {
              ...EnableWhenFields
              __typename
            }
            __typename
          }
        }

        fragment PickListOptionFields on PickListOption {
          code
          label
          secondaryLabel
          groupLabel
          groupCode
          initialSelected
          __typename
        }

        fragment EnableWhenFields on EnableWhen {
          question
          localConstant
          operator
          answerCode
          answerCodes
          answerNumber
          answerBoolean
          answerGroupCode
          compareQuestion
          __typename
        }

        fragment ProjectAccessFields on ProjectAccess {
          id
          canViewDob
          canViewFullSsn
          canDeleteProject
          canViewPartialSsn
          canEnrollClients
          canEditEnrollments
          canViewEnrollmentDetails
          canDeleteEnrollments
          canDeleteAssessments
          canEditProjectDetails
          canManageInventory
          canManageDeniedReferrals
          canManageIncomingReferrals
          canManageOutgoingReferrals
          __typename
        }
      GRAPHQL
    end

    let(:variables) do
      {
        "id": enrollment.id,
      }
    end

    it 'minimizes n+1 queries' do
      expect do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'enrollment', 'id')).to eq(enrollment.id.to_s)
      end.to make_database_queries(count: 10..100)
      # FIXME: decrease query count
      # data_collection_features and occurrence_point_form_instances both make a lot of
      # database queries for the instance table. It is a tiny table, maybe we're better
      # off loading instances into memory instead of repeated queries
    end

    it 'is responsive' do
      expect do
        _, result = post_graphql(**variables) { query }
        expect(result.dig('data', 'enrollment', 'id')).to eq(enrollment.id.to_s)
      end.to perform_under(200).ms # FIXME: improve performance
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
