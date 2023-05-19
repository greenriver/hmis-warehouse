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
      success = HmisExternalApis::AcHmis::Referral.transaction do
        referral = find_or_create_referral
        raise ActiveRecord::Rollback unless create_referral_posting(referral)
        raise ActiveRecord::Rollback unless create_referral_household_members(referral)

        success = referral
      end
      [success, errors]
    end

    protected

    def find_or_create_referral
      referral = HmisExternalApis::AcHmis::Referral
        .where(identifier: params.fetch(:referral_id))
        .first_or_initialize
      raise 'referral cant be used' unless referral.accepts_new_postings?

      referral_params = params.slice(
        :referral_date,
        :service_coordinator,
        :score,
        :needs_wheelchair_accessible_unit,
        :referral_notes,
        :chronic,
      )
      referral.update!(referral_params)
      referral
    end

    def create_referral_posting(referral)
      (posting_id, program_id, unit_type_id, referral_request_id) = params.values_at(:posting_id, :program_id, :unit_type_id, :referral_request_id)
      raise unless posting_id && program_id && unit_type_id # required fields, should be caught in validation

      return error_out('Posting ID already exists') if HmisExternalApis::AcHmis::ReferralPosting.where(identifier: posting_id).exists?

      posting = referral.postings.new(identifier: posting_id)
      posting.attributes = params.slice(:resource_coordinator_notes)
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

    def create_client(_attrs)
      client = ::Hmis::Hud::Client.new
      client.user = system_user
      client.data_source = data_source

      client.name_data_quality = 1 # Full name always present for MCI clients
      client.dob_data_quality = 1 # Full DOB always present for MCI clients
      client.ssn_data_quality = ssn.present? ? 1 : 99

      # TODO: map races and ethnicities
      HudUtility.races.keys.each { |k| client.send("#{k}=", 99) }
      # TODO: map genders
      HudUtility.gender_fields.each { |k| client.send("#{k}=", 99) }

      client.veteran_status = 99
      client.ethnicity = 99

      client.addresses = params[:addresses]&.map do |addr_params|
        Hmis::Hud::CustomClientAddress.new(
          addr_params.slice(:line1, :line2, :city, :state, :county, :use),
        )
      end

      client.contact_points = []
      client.contact_points += params[:phone_numbers].to_a.map do |phone_params|
        Hmis::Hud::CustomClientAddress.new(
          system: :phone,
          value: phone_params[:number],
          **values.slice(:use, :notes),
        )
      end
      client.contact_points += params[:email_address].to_a.map do |address|
        Hmis::Hud::CustomClientAddress.new(
          system: :email,
          value: address,
        )
      end

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
