###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ReferralsController < BaseController
    before_action :authorize_request
    skip_before_action :authenticate_user!
    prepend_before_action :skip_timeout

    def create
      # FIXME: add param validation / error handling

      referral = nil
      # transact assumes we are only mutating records in the warehouse db
      HmisExternalApis::Referral.transaction do
        referral = create_referral
        create_referral_postings(referral)
        create_referral_clients(referral)
      end
      render json: { message: 'Referral Created', id: referral.identifier }
    end

    protected

    def create_referral
      unsafe_params => {referral_id:, referral_date:, service_coordinator:}
      referral = referral_scope.new
      referral.identifier = referral_id
      referral.referral_date = referral_date
      referral.service_coordinator = :service_coordinator
      referral.raw_request = unsafe_params
      referral.save!
      referral
    end

    def create_referral_postings(referral)
      unsafe_params.fetch(:postings).map do |attrs|
        attrs => {posting_id:, referral_request_id:}
        posting = referral.referral_postings.new
        posting.identifier = posting_id
        posting.referral_request = referral_request_scope.where(identifier: referral_request_id).first!
        posting.status = 'assigned_status'
        posting.save!
        posting
      end
    end

    def create_hud_client(attrs)
      attrs => {first_name:, last_name:, middle_name:, dob:, ssn:}
      # FIXME: create MCI external id here
      client = Hmis::Hud::Client.new
      client.data_source = data_source
      client.first_name = first_name
      client.middle_name = last_name
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

      # FIXME: unsure what client.user is and why it's required. Docs needed
      user = Hmis::Hud::User.new
      user.data_source = data_source
      user.save!
      client.user = user

      client.save!
      client
    end

    def create_referral_clients(referral)
      member_params = unsafe_params.fetch(:household_members)
      mci_ids = member_params.map { |a| a.fetch(:mci_id) }
      hud_clients_by_mci_id = mci_vendor.external_ids
        .where(source_type: 'Hmis::Hud::Client')
        .where(value: mci_ids)
        .pluck(:value, :source_id)
        # external id values are not unique, pick the first record by id
        # https://github.com/greenriver/hmis-warehouse/pull/2933/files#r1164302287
        .sort_by(&:last).reverse.to_h

      member_params.map do |attrs|
        attrs => {mci_id:, relationship_to_hoh:}
        client = referral.referral_clients.new
        found_id = hud_clients_by_mci_id[mci_id]
        if found_id
          client.hud_client_id = found_id
        else
          client.hud_client = create_hud_client(attrs)
          mci_vendor.external_ids.create!(source: client.hud_client, value: mci_id)
        end
        client.save!
        client
      end
    end

    def unsafe_params
      @unsafe_params ||= params.permit!.to_h
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

    def mci_vendor
      @mci_vendor ||= GrdaWarehouse::RemoteCredentials::Token.mci
    end

  end
end
