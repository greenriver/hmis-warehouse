###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidateConsolidated < Types::BaseObject
    # object is a Hmis::Ce::Match::Candidate with unit_group_id

    field :id, ID, null: false
    field :destination_client_id, ID, null: true # destination client id
    field :source_client_id, ID, null: true # fixme implement. need to link to client. can link to warehouse?
    field :client_name, String, null: true
    field :unit_group_name, String, null: true
    field :project_name, String, null: true
    field :project_id, ID, null: true
    field :vacancies, Integer, null: false
    field :capacity, Integer, null: false
    field :organization_name, String, null: true
    field :when_added_to_candidate_pool, GraphQL::Types::ISO8601DateTime, null: true, method: :created_at
    field :when_updated_in_candidate_pool, GraphQL::Types::ISO8601DateTime, null: true, method: :updated_at
    field :priority_score, Float, null: true
    # FIXME: known FieldMap keys should be pulled out. only CDEs are fully dynamic
    field :client_attributes, GraphQL::Types::JSON, null: true
    # fixme this should be a CustomDataElement array
    field :custom_data_elements, GraphQL::Types::JSON, null: true, description: 'Custom Data Elements that contributed to eligibility and priority for this candidate pool'
    field :client_age, Integer, null: true
    field :open_enrollment_project_types, [Types::HmisSchema::Enums::ProjectType], null: true
    field :open_referral_project_types, [Types::HmisSchema::Enums::ProjectType], null: true

    # last contact date?

    def destination_client_id
      destination_client&.id
    end

    def source_client_id
      return unless destination_client

      destination_client.source_clients.where(data_source_id: current_user.hmis_data_source_id).order(:id).first.id
    end

    def client_name
      destination_client&.name
    end

    def unit_group_name
      unit_group&.name
    end

    def project_name
      project&.project_name
    end

    def project_id
      project&.id
    end
    # add: candidate pool id
    # add: source client id? how to pick, or include all HMIS?

    def client_attributes
      latest_candidate_event&.snapshot || {}
    end

    def client_age
      client_attributes.dig('current_age')
    end

    def organization_name
      load_ar_association(project, :organization)&.organization_name
    end

    def vacancies
      unit_group.opportunities.receiving_referrals.count # FIXME perf - load UnitGroup type and let it resolve this stuff?
    end

    def capacity
      unit_group.units.count # FIXME perf - load UnitGroup type and let it resolve this stuff?
    end

    def open_enrollment_project_types
      client_attributes.dig('open_enrollment_project_types')
    end

    def open_referral_project_types
      client_attributes.dig('open_referral_project_types')
    end

    def custom_data_elements
      lookup = Hmis::Hud::CustomDataElementDefinition.where(owner_type: 'Hmis::Hud::CustomAssessment').pluck(:key, :label).to_h

      client_attributes&.select { |k, _| k.start_with?('cde.custom_assessment') }&.transform_keys do |k|
        key = k.sub('cde.custom_assessment.', '')
        lookup.fetch(key, k)
      end
    end

    private

    def destination_client
      client_proxy = load_ar_association(object, :client_proxy)
      load_ar_association(client_proxy, :client) if client_proxy.client_type == 'GrdaWarehouse::Hud::Client'
    end

    def unit_group
      load_ar_scope(scope: Hmis::UnitGroup, id: object.unit_group_id)
    end

    def project
      load_ar_association(unit_group, :project)
    end

    def latest_candidate_event
      load_ar_scope(scope: Hmis::Ce::Match::CandidateEvent, id: object.latest_event_id)
    end
  end
end
