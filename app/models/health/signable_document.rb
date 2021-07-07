###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://app.hellosign.com/api/reference
#
# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient
# Control: PHI attributes documented
module Health
  class SignableDocument < HealthBase
    # phi_attr :signable_id
    # phi_attr :signable_type
    # phi_attr :primary
    # phi_attr :user_id
    # phi_attr :hs_initial_request
    # phi_attr :hs_initial_response
    phi_attr :hs_initial_response_at, Phi::Date
    # phi_attr :hs_last_response
    phi_attr :hs_last_response_at, Phi::Date
    # phi_attr :hs_subject
    # phi_attr :hs_title
    phi_attr :hs_message, Phi::FreeText
    phi_attr :signers, Phi::FreeText
    phi_attr :signed_by, Phi::FreeText
    phi_attr :expires_at, Phi::Date
    phi_attr :health_file_id, Phi::OtherIdentifier

    attr_accessor :pdf_content_to_upload

    validates :signable_id, presence: true
    validates :signable_type, presence: true
    validates :signers, length: { within: 1..5 }
    validate :signers_have_reasonable_emails
    validate :sane_number_signed

    belongs_to :signable, polymorphic: true
    # belongs_to :health_file, dependent: :destroy, class_name: 'Health::SignableDocumentFile'
    has_many :health_files, class_name: 'Health::SignableDocumentFile', foreign_key: :parent_id, dependent: :destroy
    has_one :signature_request, class_name: 'Health::SignatureRequest'
    has_one :team_member, through: :signature_request
    delegate :signed?, to: :signature_request, allow_nil: true

    scope :signed, -> do
      where("signed_by != '[]'").
        joins(signature_request: :careplan).
        merge(Health::SignatureRequest.complete)
    end

    scope :unsigned, -> do
      where("signed_by = '[]'")
    end

    scope :with_document, -> do
      where.not(health_file_id: nil)
    end

    scope :un_fetched_document, -> do
      where(health_file_id: nil)
    end

    EMAIL_REGEX = /[\w.+]+@[\w.+]+/.freeze

    def self.patient_expiration_window
      1.hours.from_now
    end

    def expired?
      expires_at.blank? || expires_at < Time.now
    end

    def make_document_signable!
      cc_email_addresses = (ENV['HELLO_SIGN_CC_EMAILS'] || '').split(/;/)

      raise 'Must save first before making a document signable (so we have the id)' if new_record?

      request = {
        test_mode: (ENV.fetch('HELLO_SIGN_TEST_MODE') { Rails.env.production? ? 0 : 1 }),
        client_id: ENV['HELLO_SIGN_CLIENT_ID'],
        title: hs_title,
        subject: hs_subject,
        message: hs_message,
        cc_email_addresses: cc_email_addresses,
        metadata: {
          signable_document_id: id,
          rails_env: Rails.env,
          hostname: `hostname`,
        },
        signers: signers.map do |signer|
          {
            name: signer.name,
            email_address: signer.email,
            # One can impose an order to signing if you want => order: @index
          }
        end,
      }

      Tempfile.open(encoding: 'ascii-8bit') do |file|
        file.write pdf_content_to_upload
        file.flush
        request[:files] = [file.path]

        # Hello Sign's ruby code modifies this, so we must copy it.
        self.hs_initial_request = request.dup

        response = hs_client.create_embedded_signature_request(request)

        self.hs_initial_response = response.data
        self.hs_initial_response_at = Time.now

        # Save a copy of this file to our health file
        @health_file = Health::SignableDocumentFile.new(
          user_id: user_id,
          client_id: signable.patient.client.id,
          file: Rails.root.join(file.path).open,
          content: Rails.root.join(file.path).read,
          content_type: 'application/pdf',
          name: 'care_plan.pdf',
          size: Rails.root.join(file.path).size,
          parent_id: id,
        )
        # There are issues with saving this that doesn't come through an upload form
        @health_file.save(validate: false)
      end
      save!
    end

    def update_health_file_from_hello_sign
      Tempfile.open(encoding: 'ascii-8bit') do |file|
        file.write remote_pdf_content
        file.flush
        health_file = Health::HealthFile.new(
          user_id: user_id,
          client_id: signable.patient.client.id,
          file: Rails.root.join(file.path).open,
          content: Rails.root.join(file.path).read,
          content_type: 'application/pdf',
          name: 'care_plan.pdf',
          size: Rails.root.join(file.path).size,
          type: Health::SignableDocumentFile.name,
          parent_id: id,
        )
        health_file.save(validate: false)
        self.health_file_id = health_file.id
      end
      save!
    end

    def update_careplan_and_health_file!(careplan)
      if careplan.patient_signed_on.blank? && signed_by?(careplan.patient.current_email)
        careplan.patient_signed_on = signed_on(careplan.patient.current_email)
        careplan.patient_signature_mode = :email
      end
      if careplan.provider_signed_on.blank? && signed_by?(careplan.provider&.email)
        careplan.provider_signed_on = signed_on(careplan.provider.email)
        careplan.provider_signature_mode = :email
      end

      return unless careplan.changed?

      if careplan.just_signed?
        last_signature = [careplan.patient_signed_on, careplan.provider_signed_on].max
        signature_request.update(completed_at: last_signature)
      end

      user = User.setup_system_user
      Health::CareplanSaver.new(careplan: careplan, user: user, create_qa: true).update
    end

    def signature_request_url(email)
      return nil unless email.match(EMAIL_REGEX)
      return nil if signed_by?(email)

      signature_id = _signature_id_for(email)

      return '' if signature_id.nil?

      Rails.cache.fetch("signature-#{signature_id}", expires_in: 1.minutes) do
        hs_client.get_embedded_sign_url(signature_id: signature_id).sign_url
      end
    end

    def signers
      raw_signers = read_attribute(:signers)
      return [] if raw_signers.nil?

      raw_signers.map do |s|
        OpenStruct.new(s)
      end
    end

    def signature_request_id
      hs_initial_response&.dig('signature_request_id')
    end

    def remote_pdf_url
      return nil unless signature_request_id.present?

      Rails.cache.fetch("signable-document-#{id}", expires_in: 5.minutes) do
        response = hs_client.signature_request_files(get_url: true, file_type: 'pdf', signature_request_id: signature_request_id)
        response['file_url']
      end
    rescue HelloSign::Error::Conflict
      'javascript:alert("The document is not ready yet")'
    end

    def remote_pdf_content
      return nil unless signature_request_id.present?

      hs_client.signature_request_files(get_url: false, file_type: 'pdf', signature_request_id: signature_request_id)
    end

    def signed_on(email)
      signature = hs_last_response['signatures'].
        find { |sig| opt_data(sig)['status_code'] == 'signed' && opt_data(sig)['signer_email_address']&.downcase == email.downcase }

      timestamp = opt_data(signature)['signed_at'] if signature.present?

      return nil unless timestamp.present?

      Time.at(timestamp)
    end

    def signer_hash(email)
      Digest::MD5.hexdigest(_signature_id_for(email) + ENV['HELLO_SIGN_HASH_SALT'].to_s)
    end

    # Can't send reminders through HS when doing embedded documents.
    # def remind!(email)
    #   #TDB: change to deliver_later?
    #   HelloSignMailer.careplan_signature_request(doc_id: self.id, email: email).deliver
    # end

    def update_who_signed_from_hello_sign_callback!(callback_payload = fetch_signature_request)
      return if all_signed?

      self.hs_last_response_at = Time.now
      self.hs_last_response = callback_payload
      sig_hashes = hs_last_response['signatures'].select { |sig| opt_data(sig)['status_code'] == 'signed' }
      new_signers = sig_hashes.map { |sig| opt_data(sig)['signer_email_address'] }
      self.signed_by = new_signers
      save!
    end

    def signed_by?(email)
      return false if signed_by.blank?
      return false if email.blank?

      signed_by.any? { |signer| signer.downcase == email.downcase }
    end

    def all_signed?
      return false if signers.length.zero?

      signers.all? { |signer| signed_by?(signer.email) }
    end

    def fetch_signature_request
      hs_client.get_signature_request(signature_request_id: signature_request_id).data
    end

    private def _signature_id_for(email)
      return nil if email.blank?
      return nil if hs_initial_response.nil?

      sig = Array.wrap(hs_initial_response['signatures']).find { |r| opt_data(r).dig('signer_email_address')&.downcase == email.downcase }
      res = opt_data(sig)

      res.present? ? res['signature_id'] : 'error'
    end

    # HelloSign will fail if given bad emails
    private def signers_have_reasonable_emails
      signers.each do |signer|
        errors[:signers] << "contain at least one bad email address (#{signer['email']})." unless signer['email'].to_s.match(EMAIL_REGEX)
      end
    end

    private def hs_client
      @hs_client ||= ::HelloSign::Client.new(api_key: ENV['HELLO_SIGN_API_KEY'])
    end

    private def sane_number_signed
      return if signed_by.nil?
      return if signed_by.length <= signers.length

      errors[:signed_by] << 'Cannot be longer than potential number of signers'
    end

    private def opt_data(json)
      json&.dig('data') || json
    end

    def self.process_unfetched_signed_documents
      un_fetched_document.signed.find_each.with_index do |doc, i|
        # Make sure everything we need exists -- signable is polymorphic, so we can't join on it
        next unless doc.signable&.patient&.client&.present?

        # Hello Sign has a rate limit of 25 requests per minute.
        # Throw some sand in the system before we enqueue the next so we don't hit it.
        wait = i + 1 * 10.seconds
        UpdateHealthFileFromHelloSignJob.set(wait: wait).perform_later(doc.id)
      end
    end
  end
end
