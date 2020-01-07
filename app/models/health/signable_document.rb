###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# https://app.hellosign.com/api/reference
#
# ### HIPPA Risk Assessment
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
    # belongs_to :health_file, dependent: :destroy, class_name: Health::SignableDocumentFile.name
    has_many :health_files, class_name: 'Health::SignableDocumentFile', foreign_key: :parent_id, dependent: :destroy
    has_one :signature_request, class_name: Health::SignatureRequest.name
    has_one :team_member, through: :signature_request
    delegate :signed?, to: :signature_request, allow_nil: true

    scope :signed, -> do
      where.not(signed_by: '[]').
      joins(:signature_request).merge(Health::SignatureRequest.complete)
    end

    scope :unsigned, -> do
      where(signed_by: '[]')
    end

    scope :with_document, -> do
      where.not(health_file_id: nil)
    end

    scope :un_fetched_document, -> do
      where(health_file_id: nil)
    end

    EMAIL_REGEX = /[\w.+]+@[\w.+]+/

    def self.patient_expiration_window
      1.hours.from_now
    end

    def expired?
      expires_at.blank? || expires_at < Time.now
    end


    def make_document_signable!
      cc_email_addresses = (ENV['HELLO_SIGN_CC_EMAILS']||'').split(/;/)

      raise "Must save first before making a document signable (so we have the id)" if new_record?

      request = {
        test_mode: (ENV.fetch('HELLO_SIGN_TEST_MODE') { Rails.env.production? ? 0 : 1}),
        client_id: ENV['HELLO_SIGN_CLIENT_ID'],
        title: self.hs_title,
        subject: self.hs_subject,
        message: self.hs_message,
        cc_email_addresses: cc_email_addresses,
        metadata: {
          signable_document_id: self.id,
          rails_env: Rails.env,
          hostname: `hostname`
        },
        signers: self.signers.map { |signer|
          {
            name: signer.name,
            email_address: signer.email,
            # One can impose an order to signing if you want => order: @index
          }
        }
      }

      Tempfile.open(encoding: 'ascii-8bit') do |file|
        file.write self.pdf_content_to_upload
        file.flush
        request[:files] = [ file.path ]

        # Hello Sign's ruby code modifies this, so we must copy it.
        self.hs_initial_request = request.dup

        response = hs_client.create_embedded_signature_request(request)

        self.hs_initial_response = response.data
        self.hs_initial_response_at = Time.now

        # Save a copy of this file to our health file
        @health_file = Health::SignableDocumentFile.new(
          user_id: self.user_id,
          client_id: signable.patient.client.id,
          file: Rails.root.join(file.path).open,
          content: Rails.root.join(file.path).read,
          content_type: 'application/pdf',
          name: 'care_plan.pdf',
          size: Rails.root.join(file.path).size,
          parent_id: self.id
        )
        # There are issues with saving this that doesn't come through an upload form
        @health_file.save(validate: false)
      end
      save!
    end

    def update_health_file_from_hello_sign
      Tempfile.open(encoding: 'ascii-8bit') do |file|
        file.write self.remote_pdf_content
        file.flush
        health_file = Health::HealthFile.new(
            user_id: self.user_id,
            client_id: signable.patient.client.id,
            file: Rails.root.join(file.path).open,
            content: Rails.root.join(file.path).read,
            content_type: 'application/pdf',
            name: 'care_plan.pdf',
            size: Rails.root.join(file.path).size,
            type: Health::SignableDocumentFile.name,
            parent_id: self.id
          )
        health_file.save(validate: false)
        self.health_file_id = health_file.id
      end
      save!
    end

    def update_careplan_and_health_file!(careplan)
      # Process patient signature
      if careplan.patient_signed_on.blank? && self.signed_by?(careplan.patient.current_email)
        user = User.setup_system_user
        careplan.patient_signed_on = self.signed_on(careplan.patient.current_email)
        Health::CareplanSaver.new(careplan: careplan, user: user, create_qa: true).update
        self.signature_request.update(completed_at: careplan.patient_signed_on)

        #update_health_file_from_hello_sign
        # Need to wait for pdf to be ready
        UpdateHealthFileFromHelloSignJob.
          set(wait: 30.seconds).
          perform_later(self.id)
      elsif careplan.provider.present? && self.signed_by?(careplan.provider.email)
        # process PCP signature, careplan has already been updated, we just need to fetch the file
        UpdateHealthFileFromHelloSignJob.
          set(wait: 30.seconds).
          perform_later(self.id)
      end

    end

    def signature_request_url(email)
      if !email.match(EMAIL_REGEX)
        return nil
      end

      if signed_by?(email)
        return nil
      end

      signature_id = _signature_id_for(email)

      return '' if signature_id.nil?

      Rails.cache.fetch("signature-#{signature_id}", expires_in: 1.minutes) do
        hs_client.get_embedded_sign_url(signature_id: signature_id).sign_url
      end
    end

    def signers
      read_attribute(:signers).map do |s|
        OpenStruct.new(s)
      end
    end

    def signature_request_id
      self.hs_initial_response&.dig('signature_request_id')
    end

    def remote_pdf_url
      return nil unless self.signature_request_id.present?

      Rails.cache.fetch("signable-document-#{self.id}", expires_in: 5.minutes) do
        response = hs_client.signature_request_files(get_url: true, file_type: 'pdf', signature_request_id: self.signature_request_id)
        response['file_url']
      end
    rescue HelloSign::Error::Conflict
      'javascript:alert("The document is not ready yet")'
    end

    def remote_pdf_content
      return nil unless self.signature_request_id.present?

      hs_client.signature_request_files(get_url: false, file_type: 'pdf', signature_request_id: self.signature_request_id)
    end

    def signed_on(email)
      timestamp = self.hs_last_response['signatures'].
        find { |sig| sig['status_code'] == 'signed' && sig['signer_email_address'] == email }&.
        dig('signed_at')

      return nil unless timestamp.present?

      Time.at(timestamp)
    end

    def signer_hash(email)
      Digest::MD5.hexdigest(_signature_id_for(email)+ENV['HELLO_SIGN_HASH_SALT'].to_s)
    end

    # Can't send reminders through HS when doing embedded documents.
    # def remind!(email)
    #   #TDB: change to deliver_later?
    #   HelloSignMailer.careplan_signature_request(doc_id: self.id, email: email).deliver
    # end

    def update_who_signed_from_hello_sign_callback!(callback_payload=fetch_signature_request)
      return if all_signed?

      self.hs_last_response_at = Time.now
      self.hs_last_response = callback_payload
      sig_hashes = self.hs_last_response['signatures'].select { |sig| sig['status_code'] == 'signed' }
      new_signers = sig_hashes.map { |sig| sig['signer_email_address']  }
      self.signed_by = new_signers
      self.save!
    end

    def signed_by?(email)
      signed_by.any? { |signer| signer == email }
    end

    def all_signed?
      return false if signers.length == 0

      signers.all? { |signer| signed_by?(signer.email) }
    end

    def fetch_signature_request
      hs_client.get_signature_request(signature_request_id: self.signature_request_id).data
    end

    private

    def _signature_id_for(email)
      return nil if self.hs_initial_response.nil?

      res = Array.wrap(self.hs_initial_response['signatures']).find do |r|
        r.dig('data', 'signer_email_address') == email
      end['data']

      res.present? ? res['signature_id'] : 'error'
    end

    # HelloSign will fail if given bad emails
    def signers_have_reasonable_emails
      self.signers.each do |signer|
        if !signer['email'].to_s.match(EMAIL_REGEX)
          errors[:signers] << "contain at least one bad email address (#{signer['email']})."
        end
      end
    end

    def hs_client
      @client ||= ::HelloSign::Client.new(api_key: ENV['HELLO_SIGN_API_KEY'])
    end

    def sane_number_signed
      return if signed_by.length <= signers.length

      errors[:signed_by] << "Cannot be longer than potential number of signers"
    end

  end
end
