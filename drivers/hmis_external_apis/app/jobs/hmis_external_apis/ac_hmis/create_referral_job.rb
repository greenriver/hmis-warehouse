###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class CreateReferralJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin
    attr_accessor :params, :errors

    # @param params [Hash] api payload
    def perform(params:)
      self.params = params.deep_symbolize_keys
      # FIXME: add param validation and capture raw request

      self.errors = []
      success = nil
      # transact assumes we are only mutating records in the warehouse db
      HmisExternalApis::AcHmis::Referral.transaction do
        referral = create_referral
        raise ActiveRecord::Rollback unless create_referral_posting(referral)

        raise ActiveRecord::Rollback unless create_referral_household_members(referral)

        success = referral
      end
      [success, errors]
    end

    protected

    def create_referral
      params => {referral_id:, referral_date:, service_coordinator:}
      referral = HmisExternalApis::AcHmis::Referral.new
      referral.identifier = referral_id
      referral.referral_date = referral_date
      referral.service_coordinator = :service_coordinator
      referral.save!
      referral
    end

    def create_referral_posting(referral)
      (posting_id, program_id, unit_type_id, referral_request_id) = params.values_at(:posting_id, :program_id, :unit_type_id, :referral_request_id)
      raise unless posting_id && program_id && unit_type_id # required fields, should be caught in validation

      posting = referral.postings.new(identifier: posting_id)
      posting.project = mper.find_project_by_mper(program_id)
      return error_out('Project not found') unless posting.project

      if referral_request_id
        # the posting references an existing referral request
        posting.referral_request = HmisExternalApis::AcHmis::ReferralRequest
          .where(identifier: referral_request_id).first
        return error_out('Referral Request not found') unless posting.referral_request

        return error_out('Referral Request does not match Project') unless
          posting.referral_request.project_id == posting.project_id
      end

      posting.unit_type = mper.find_unit_type_by_mper(unit_type_id)
      return error_out('Unit Type not found') unless posting.unit_type

      posting.status = 'assigned_status'
      posting.save!
      posting
    end

    def create_client(attrs)
      (first_name, last_name, middle_name, dob, ssn) = attrs.values_at(:first_name, :last_name, :middle_name, :dob, :ssn)
      client = ::Hmis::Hud::Client.new
      client.user = system_user
      client.data_source = data_source
      client.first_name = first_name
      client.middle_name = middle_name
      client.last_name = last_name
      client.dob = dob
      client.ssn = ssn

      client.name_data_quality = 1 # Full name always present for MCI clients
      client.dob_data_quality = 1 # Full DOB always present for MCI clients
      client.ssn_data_quality = ssn.present? ? 1 : 99

      # TODO: map races and ethnicities
      HudUtility.races.keys.each { |k| client.send("#{k}=", 99) }
      # TODO: map genders
      HudUtility.gender_fields.each { |k| client.send("#{k}=", 99) }

      client.veteran_status = 99
      client.ethnicity = 99
      client.save!
      client
    end

    def create_referral_household_members(referral)
      member_params = params.fetch(:household_members)

      member_params.map do |attrs|
        attrs => {mci_id:, relationship_to_hoh:}
        member = referral.household_members.new
        member.relationship_to_hoh = relationship_to_hoh
        found = mci.find_client_by_mci(mci_id)
        if found
          member.client = found
          # TODO: update client attributes based on the values we received
        else
          member.client = create_client(attrs)
          mci.create_external_id(source: member.client, value: mci_id)
        end
        member.save!
        member
      end
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def system_user
      @system_user ||= ::Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end

    def error_out(msg)
      errors.push(msg)
      return false
    end
  end
end
