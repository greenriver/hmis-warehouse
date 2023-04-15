###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class CreateReferralJob < ApplicationJob
    attr_accessor :params

    # @param params [Hash] api payload
    def perform(params:)
      self.params = params
      # FIXME: add param validation and capture raw request

      referral = nil
      # transact assumes we are only mutating records in the warehouse db
      HmisExternalApis::Referral.transaction do
        referral = create_referral
        create_referral_postings(referral)
        create_referral_household_members(referral)
      end
      referral
    end

    protected

    def create_referral
      params => {referral_id:, referral_date:, service_coordinator:}
      referral = referral_scope.new
      referral.identifier = referral_id
      referral.referral_date = referral_date
      referral.service_coordinator = :service_coordinator
      referral.save!
      referral
    end

    def mper_cred
      @mper_cred ||= GrdaWarehouse::RemoteCredential.mper
    end

    def create_referral_postings(referral)
      posting_attrs = params.fetch(:postings)

      # build lookup tables for entities referenced in postings; avoid n+1 queries
      referral_requests_by_identifier = posting_attrs
        .map { |h| h[:referral_request_id] }
        .compact
        .then do |ids|
          ids.any? ? referral_request_scope.preload(:project, :unit_type).where(identifier: ids).index_by(&:identifier) : {}
        end
      projects_ids_by_mper_id = external_id_map(
        cred: mper_cred,
        scope: Hmis::Hud::Project,
        external_ids: posting_attrs.map { |a| a[:program_id] }.compact,
      )

      posting_attrs.map do |attrs|
        (posting_id, referral_request_id, program_id) = attrs.values_at(:posting_id, :referral_request_id, :program_id).map(&:presence)
        raise unless posting_id

        posting = referral.postings.new(identifier: posting_id)
        if referral_request_id
          # the posting references an existing referral request
          referral_request = referral_requests_by_identifier.fetch(referral_request_id)
          posting.referral_request = referral_request
          # posting.referral_request is optional; denormalize fields for consistency
          posting.project = referral_request.project
          # posting.unit_type = referral_request.unit_type
        elsif program_id
          # the posting is an assignment, the program id is MPER project ID
          posting.project_id = projects_ids_by_mper_id.fetch(program_id)
          # posting.unit_type = unit_types_by_identifier.fetch(unit_type_id)
        else
          raise "unexpected referral posting: #{attrs.inspect}"
        end
        posting.status = 'assigned_status'
        posting.save!
        posting
      end
    end

    def create_client(attrs)
      attrs => {first_name:, last_name:, middle_name:, dob:, ssn:}
      client = Hmis::Hud::Client.new
      client.user = system_user
      client.data_source = data_source
      client.first_name = first_name
      client.middle_name = middle_name
      client.last_name = last_name
      client.dob = dob
      client.ssn = ssn

      # DQ = 1 needed for validations
      client.NameDataQuality = 1
      client.SSNDataQuality = 1
      client.DOBDataQuality = 1

      # FIXME- demographics need to be mapped.
      # set dummy values for now to let validation pass
      client.AmIndAKNative = 0
      client.Asian = 0
      client.BlackAfAmerican = 0
      client.NativeHIPacific = 0
      client.White = 0
      client.Ethnicity = 0
      client.Female = 0
      client.Male = 0
      client.NoSingleGender = 0
      client.Transgender = 0
      client.Questioning = 0
      client.Gender = 0
      client.VeteranStatus = 0

      client.save!
      client
    end

    def create_referral_household_members(referral)
      member_params = params.fetch(:household_members)
      clients_ids_by_mci_id = external_id_map(
        cred: mci_cred,
        scope: Hmis::Hud::Client,
        external_ids: member_params.map { |a| a.fetch(:mci_id) },
      )

      member_params.map do |attrs|
        attrs => {mci_id:, relationship_to_hoh:}
        member = referral.household_members.new
        member.relationship_to_hoh = relationship_to_hoh
        found_id = clients_ids_by_mci_id[mci_id]
        if found_id
          member.client_id = found_id
        else
          member.client = create_client(attrs)
          mci_cred.external_ids.create!(source: member.client, value: mci_id)
        end
        member.save!
        member
      end
    end

    def authorize_request
      # FIXME: token auth or oauth?
      raise unless Rails.env.development? || Rails.env.test?
    end

    def referral_scope
      HmisExternalApis::Referral
    end

    def referral_request_scope
      HmisExternalApis::ReferralRequest
    end

    def data_source
      # FIXME: not sure what the data source is
      @data_source ||= GrdaWarehouse::DataSource.hmis.first!
    end

    def system_user
      @system_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end

    def mci_cred
      @mci_cred ||= GrdaWarehouse::RemoteCredential.mci
    end

    # map records from external_ids to local db ids
    # @param cred: GrdaWarehouse::RemoteCredential
    # @param external_ids [Array<String>]
    # @param scope [ActiveRecord::Relation] must respond to created_at order
    def external_id_map(cred:, external_ids:, scope:)
      return {} if external_ids.empty?

      ret = {}
      scope
        .joins(:external_ids)
        .where(external_ids: { value: external_ids, remote_credential: cred })
        .order(created_at: :asc, id: :asc)
        .pluck('external_ids.value', :id)
        .each do |mci_id, client_id|
          # external id values are not unique, to_h will choose the record with the earliest timestamp
          # https://github.com/greenriver/hmis-warehouse/pull/2955/files#r1166824257
          ret[mci_id] ||= client_id
        end
      ret
    end
  end
end
