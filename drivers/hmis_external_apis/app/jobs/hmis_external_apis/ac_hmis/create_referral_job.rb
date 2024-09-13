###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class CreateReferralJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
    include HmisExternalApis::AcHmis::ReferralJobMixin
    attr_accessor :params, :errors

    # @param params [Hash] api payload
    def perform(...)
      with_lock do
        perform_in_tx(...)
      end
    end

    protected

    def with_lock(timeout_seconds: 5)
      lock_name = self.class.name.demodulize
      HmisExternalApis::AcHmis::Referral.with_advisory_lock(lock_name, timeout_seconds: timeout_seconds) do
        yield
      end
    end

    def perform_in_tx(params:)
      self.params = params.deep_symbolize_keys
      self.errors = []

      # Idempotent - Check for existing posting and return early if it exists
      posting = existing_posting
      return [posting.referral, errors, 'Referral Found'] if posting
      # Return early in case of errors too, so we don't proceed with trying to create the referral
      return [nil, errors] unless errors.empty?

      # transact assumes we are only mutating records in the warehouse db
      record = nil
      HmisExternalApis::AcHmis::Referral.transaction do
        referral = find_or_create_referral
        raise ActiveRecord::Rollback unless referral

        raise ActiveRecord::Rollback unless create_referral_posting(referral)

        Hmis::Hud::Client.without_optimistic_locking do
          raise ActiveRecord::Rollback unless create_or_update_referral_household_members(referral)
        end

        record = referral
      end
      [record, errors, 'Referral Created']
    end

    def existing_posting
      existing = HmisExternalApis::AcHmis::ReferralPosting.find_by(identifier: params.fetch(:posting_id))

      if existing.present?
        return error_out('Posting already exists with a different Referral ID') unless existing.referral.identifier == params.fetch(:referral_id).to_s

        project = mper.find_project_by_mper(params.fetch(:program_id))
        return error_out('Project not found') unless project
        return error_out('Posting already exists with a different project') unless existing.project == project
      end

      existing
    end

    def find_or_create_referral
      referral = HmisExternalApis::AcHmis::Referral.
        where(identifier: params.fetch(:referral_id)).
        first_or_initialize
      return error_out('Referral still has active postings') unless referral.postings_inactive?

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

      posting = referral.postings.new(identifier: posting_id)
      posting.attributes = params.slice(:resource_coordinator_notes)
      posting.project = mper.find_project_by_mper(program_id)
      return error_out('Project not found') unless posting.project

      if referral_request_id
        # the posting references an existing referral request
        posting.referral_request = HmisExternalApis::AcHmis::ReferralRequest.
          where(identifier: referral_request_id).first
        return error_out('Referral Request not found') unless posting.referral_request

        return error_out('Referral Request does not match Project') unless
          posting.referral_request.project_id == posting.project_id
      end

      posting.unit_type = mper.find_unit_type_by_mper(unit_type_id)
      return error_out('Unit Type not found') unless posting.unit_type

      posting.data_source = data_source
      posting.status = 'assigned_status'
      posting.save!
      posting
    end

    def update_client(client, attrs)
      setup_client_name(client, attrs) # reconcile CustomClientNames and assign Client name attributes
      client.attributes = attrs.slice(:dob, :ssn, :veteran_status, :different_identity_text, :additional_race_ethnicity)

      client.name_data_quality = 1 # Full name always present for MCI clients
      client.dob_data_quality = 1 # Full DOB always present for MCI clients
      client.ssn_data_quality = client.ssn.present? ? 1 : 99
      client.assign_attributes(**race_attributes_from_codes(attrs[:race] || []))
      client.assign_attributes(**gender_attributes_from_codes(attrs[:gender] || []))
      client.veteran_status ||= 99
      client.save!

      # additional attributes set if this client is the HOH
      is_hoh = attrs[:relationship_to_hoh] == 1
      update_client_addresses(client) if is_hoh
      update_client_contacts(client) if is_hoh
    end

    def build_client
      client = ::Hmis::Hud::Client.new
      client.user = system_user
      client.data_source = data_source
      client
    end

    # reconcile client record name and client custom names (ccn)
    def setup_client_name(client, attrs)
      attrs[:name_suffix] = attrs.delete :suffix # rename key to match table column

      # fields received
      name_fields = [:first_name, :middle_name, :last_name, :name_suffix]

      # first_name => 'Jane', middle_name => '', last_name => 'Smith', name_suffix => 'Jr'
      input_attrs = attrs.slice(*name_fields).stringify_keys

      # {firstName => 'Jane', middleName =>, lastName => 'Smith', nameSuffix => 'Jr'
      prev_attrs = client.attributes.slice(*name_fields.map(&:to_s).map(&:camelize))

      # assign directly to record if new_record
      return client.attributes = input_attrs if client.new_record?

      # name matches, no-op
      return if prev_attrs.values == input_attrs.values

      # first => 'Jane', middle => '', last => 'Smith'
      prev_ccn_attrs = prev_attrs.transform_keys { |k| k.gsub(/Name/, '').downcase }
      # keep previous ccn as a non-primary custom name
      if prev_ccn_attrs.values.compact_blank.any?
        prev_ccn = client.names.where(prev_ccn_attrs).first_or_initialize
        assign_default_common_client_attrs(client, prev_ccn)
        prev_ccn.name_data_quality ||= 1
        prev_ccn.primary = false
        prev_ccn.save!
      end

      # first => 'Jane', middle => '', last => 'Smith'
      input_ccn_attrs = input_attrs.transform_keys { |k| k.gsub(/_?name_?/i, '') }
      # ensure new ccn is a primary custom name
      new_ccn = client.names.where(input_ccn_attrs).first_or_initialize
      assign_default_common_client_attrs(client, new_ccn)
      new_ccn.name_data_quality = 1
      new_ccn.primary = true
      new_ccn.save!

      # ensure the ccn is the only primary
      client.names.where.not(id: new_ccn.id).update_all(primary: false)
      # propagate the primary name to the client record
      client.assign_primary_name_fields
    end

    # Add/update addresses
    def update_client_addresses(client)
      old_addresses = client.addresses
      new_addresses = []
      params[:addresses].to_a.each do |values|
        address = Hmis::Hud::CustomClientAddress.new(
          postal_code: values[:zip],
          district: values[:county],
          **values.slice(
            :line1,
            :line2,
            :city,
            :state,
            :use,
          ),
          **common_client_attrs(client),
        )
        new_addresses << address unless update_duplicate_record!(old_addresses, address)
      end

      Hmis::Hud::CustomClientAddress.import!(new_addresses)
    end

    # Add/update phones and emails
    def update_client_contacts(client)
      old_contact_points = client.contact_points
      new_contact_points = []
      params[:phone_numbers].to_a.each do |values|
        phone = Hmis::Hud::CustomClientContactPoint.new(
          system: :phone,
          value: values[:number],
          use: values[:type],
          notes: values[:notes],
          **common_client_attrs(client),
        )
        new_contact_points << phone unless update_duplicate_record!(old_contact_points, phone)
      end

      params[:email_address].to_a.each do |value|
        email = Hmis::Hud::CustomClientContactPoint.new(
          system: :email,
          value: value,
          **common_client_attrs(client),
        )
        new_contact_points << email unless update_duplicate_record!(old_contact_points, email)
      end

      Hmis::Hud::CustomClientContactPoint.import!(new_contact_points)
    end

    def common_client_attrs(client)
      {
        PersonalID: client.PersonalID,
        UserID: system_user.UserID,
        data_source_id: client.data_source_id,
      }
    end

    def update_duplicate_record!(old_records, new_record)
      dup = old_records.find { |old| old.equal_for_merge?(new_record) }
      return false unless dup.present?

      dup.assign_attributes(new_record.attributes.compact_blank)
      dup.save!
    end

    def assign_default_common_client_attrs(client, record)
      common_client_attrs(client).each do |attr, value|
        record[attr] ||= value
      end
    end

    def create_or_update_referral_household_members(referral)
      member_params = params.fetch(:household_members)
      return error_out('Household must have exactly one HoH') if member_params.map { |m| m[:relationship_to_hoh] }.count(1) != 1

      old_members = referral.household_members.index_by(&:id)
      member_params.each do |attrs|
        attrs => {mci_id:, relationship_to_hoh:}
        found = mci.find_client_by_mci(mci_id)
        client = found || build_client
        update_client(client, attrs)
        mci.create_external_id(source: client, value: mci_id) unless found

        member = referral.household_members.where(client: client).first_or_initialize
        old_members.delete(member.id) if member.persisted?
        member.relationship_to_hoh = relationship_to_hoh
        member.mci_id = mci_id
        member.save!
      end
      old_members.values.each(&:destroy!)
      true
    end

    def error_out(msg)
      errors.push(msg)
      return false
    end

    # Accepts a list of 2024 integer values for gender from Data Dictionary
    def gender_attributes_from_codes(codes)
      attributes = HudUtility2024.gender_id_to_field_name.invert.excluding(:GenderNone).map do |k, v|
        [k, codes.include?(v) ? 1 : 0]
      end.to_h
      attributes[:GenderNone] = attributes.values.sum.zero? ? 99 : nil
      attributes
    end

    # Accepts a list of 2024 integer values for race from Data Dictionary
    def race_attributes_from_codes(codes)
      attributes = HudUtility2024.race_id_to_field_name.invert.excluding(:RaceNone).map do |k, v|
        [k, codes.include?(v) ? 1 : 0]
      end.to_h
      attributes[:RaceNone] = attributes.values.sum.zero? ? 99 : nil
      attributes
    end
  end
end
