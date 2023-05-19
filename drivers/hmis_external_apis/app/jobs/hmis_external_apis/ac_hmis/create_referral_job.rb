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
      # transact assumes we are only mutating records in the warehouse db
      record = nil
      HmisExternalApis::AcHmis::Referral.transaction do
        referral = find_or_create_referral
        raise ActiveRecord::Rollback unless referral

        raise ActiveRecord::Rollback unless create_referral_posting(referral)

        raise ActiveRecord::Rollback unless create_referral_household_members(referral)

        record = referral
      end
      [record, errors]
    end

    protected

    def find_or_create_referral
      referral = HmisExternalApis::AcHmis::Referral
        .where(identifier: params.fetch(:referral_id))
        .first_or_initialize
      return error_out('Referral still has active postings') unless referral.postings_inactive?
      return error_out('Referral already linked to household') unless referral.household_members.empty?

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

    def create_client(attrs)
      client = ::Hmis::Hud::Client.new(
        attrs.slice(:first_name, :last_name, :middle_name, :dob, :ssn),
      )
      client.user = system_user
      client.data_source = data_source

      client.name_data_quality = 1 # Full name always present for MCI clients
      client.dob_data_quality = 1 # Full DOB always present for MCI clients
      client.ssn_data_quality = client.ssn.present? ? 1 : 99

      # TODO: map races and ethnicities
      HudUtility.races.keys.each { |k| client.send("#{k}=", 99) }
      # TODO: map genders
      HudUtility.gender_fields.each { |k| client.send("#{k}=", 99) }

      client.veteran_status = 99
      client.ethnicity = 99
      client.save!

      # additional attributes set if this client is the hoh
      setup_hoh(client) if attrs[:relationship_to_hoh] == 1

      client
    end

    def setup_hoh(client)
      common_client_attrs = {
        PersonalID: client.PersonalID,
        UserID: client.UserID,
        data_source_id: client.data_source_id,
      }
      client_address_attrs = params[:addresses].to_a.map do |values|
        {
          postal_code: values[:zip],
          **values.slice(
            :line1,
            :line2,
            :city,
            :state,
            :use,
            # :county,  FIXME - spec doc has a "county" field; We don't have that but we do have "country" - maybe there's a typo somewhere?
          ),
          # FIXME: unsure what to do with this, use uuid for now
          AddressID: bogus_id,
          **common_client_attrs,
        }
      end
      Hmis::Hud::CustomClientAddress.import!(client_address_attrs)

      client_phone_attrs = params[:phone_numbers].to_a.map do |values|
        {
          system: :phone,
          value: values[:number],
          **values.slice(:use, :notes),
          # FIXME: unsure what to do with this, use uuid for now
          ContactPointID: bogus_id,
          **common_client_attrs,
        }
      end
      Hmis::Hud::CustomClientContactPoint.import!(client_phone_attrs)

      client_email_attrs = params[:email_address].to_a.map do |value|
        {
          system: :email,
          value: value,
          # FIXME: unsure what to do with this, use uuid for now
          ContactPointID: bogus_id,
          **common_client_attrs,
        }
      end
      Hmis::Hud::CustomClientContactPoint.import!(client_email_attrs)
    end

    def bogus_id
      SecureRandom.uuid
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
