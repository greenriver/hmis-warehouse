require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let!(:ds1) { create :source_data_source, hmis: GraphqlHelpers::HMIS_HOSTNAME }
  let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let!(:p1) { create :hmis_hud_project, data_source_id: ds1.id, organization: o1 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1 }

  let(:test_input) do
    {
      enrollment_id: e1.id,
      client_id: c1.id,
      date_provided: Date.today.strftime('%Y-%m-%d'),
      record_type: Types::HmisSchema::Enums::RecordType.enum_member_for_value(144).first,
      type_provided: Types::HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value('144:3').first,
      sub_type_provided: Types::HmisSchema::Enums::ServiceSubTypeProvided.enum_member_for_value('144:3:1').first,
      other_type_provided: 'Other Type',
      moving_on_other_type: 'Moving On Other Type',
      'FAAmount' => 1.5,
      referral_outcome: Types::HmisSchema::Enums::PATHReferralOutcome.enum_member_for_value(1).first,
    }
  end

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })

    @hmis_user = Hmis::User.find(user.id)
    @hmis_user.hmis_data_source_id = ds1.id
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateService($input: ServiceInput!) {
        createService(input: { input: $input }) {
          service {
            id
            enrollment {
              id
            }
            client {
              id
            }
            dateProvided
            recordType
            typeProvided
            subTypeProvided
            otherTypeProvided
            movingOnOtherType
            FAAmount
            referralOutcome
          }
          errors {
            attribute
            message
            fullMessage
            type
            options
            __typename
          }
        }
      }
    GRAPHQL
  end

  it 'should create a service successfully' do
    response, result = post_graphql(input: test_input) { mutation }

    expect(response.status).to eq 200
    service = result.dig('data', 'createService', 'service')
    errors = result.dig('data', 'createService', 'errors')

    expect(service['id']).to be_present
    expect(errors).to be_empty
  end

  it 'should throw errors if the service is invalid' do
    response, result = post_graphql(input: {}) { mutation }

    service = result.dig('data', 'createService', 'service')
    errors = result.dig('data', 'createService', 'errors')

    expect(response.status).to eq 200
    expect(service).to be_nil
    expect(errors).to be_present
  end

  describe 'Validity tests' do
    [
      # [
      #   'should emit error if organization ID is not provided',
      #   ->(input) { input.except(:organization_id) },
      #   {
      #     'fullMessage' => 'Organization must exist',
      #     'attribute' => 'organization',
      #   },
      #   {
      #     'fullMessage' => 'Organizationid must exist',
      #     'attribute' => 'organizationId',
      #   },
      # ],
      # [
      #   'should emit error if name is not provided',
      #   ->(input) { input.except(:project_name) },
      #   {
      #     'fullMessage' => 'Projectname must exist',
      #     'attribute' => 'projectName',
      #   },
      # ],
      # [
      #   'should emit error if name is not provided',
      #   ->(input) { input.except(:operating_start_date) },
      #   {
      #     'fullMessage' => 'Operatingstartdate must exist',
      #     'attribute' => 'operatingStartDate',
      #   },
      # ],
      # [
      #   'should emit error if project type is not provided and project is not a continuum project',
      #   ->(input) { input.except(:project_type) },
      #   {
      #     'fullMessage' => 'Project type must exist',
      #     'attribute' => 'projectType',
      #   },
      # ],
      # [
      #   'should not emit error if project type is not provided and project is a continuum project',
      #   ->(input) { input.except(:project_type).merge(continuum_project: true) },
      # ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input: input) { mutation }
        errors = result.dig('data', 'createService', 'errors')
        expect(response.status).to eq 200
        expect(errors).to contain_exactly(*expected_errors.map { |error_attrs| include(**error_attrs) })
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
