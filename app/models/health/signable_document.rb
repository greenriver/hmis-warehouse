# https://app.hellosign.com/api/reference
module Health
  class SignableDocument < HealthBase
    attr_accessor :pdf_content_to_upload

    validates :signable_id, presence: true
    validates :signable_type, presence: true
    validates :signers, length: { within: 1..5 }
    validate :signers_have_reasonable_emails
    validate :sane_number_signed

    belongs_to :signable, polymorphic: true
    belongs_to :health_file, dependent: :destroy, class_name: Health::SignableDocumentFile.name

    EMAIL_REGEX = /[\w.+]+@[\w.+]+/

    def self.patient_expiration_window
      1.hours.from_now
    end

    def expired?
      expires_at.blank? || expires_at < Time.now
    end

    def make_document_signable!
      cc_email_addresses = (ENV['HELLO_SIGN_CC_EMAILS']||'').split(/;/)

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
        @health_file = Health::HealthFile.new(
          user_id: self.user_id,
          client_id: signable.patient.client.id,
          file: Rails.root.join(file.path).open,
          content: Rails.root.join(file.path).read,
          content_type: 'application/pdf',
          name: 'care_plan.pdf',
          size: Rails.root.join(file.path).size,
          type: Health::SignableDocumentFile.name
        )
        # There are issues with saving this that doesn't come through an upload form
        @health_file.save(validate: false)
        self.health_file_id = @health_file.id
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
            type: Health::SignableDocumentFile.name
          )
        health_file.save(validate: false)
        self.health_file_id = health_file.id
      end
      save!
    end

    def update_signers(careplan)
      if careplan.patient_signed_on.blank? && self.signed_by?('patient@openpath.biz')
        careplan.patient_signed_on = self.signed_on('patient@openpath.biz')
        # ensure we capture the signed document
        # TODO: sometimes this is too soon and gets an unsigned version
        update_health_file_from_hello_sign
      end
    end

    def signature_request_url(email)
      if !email.match(EMAIL_REGEX)
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
    def remind!(email)
      #TDB: change to deliver_later?
      HelloSignMailer.careplan_signature_request(doc: self, email: email).deliver
    end

    #TDB: Hook to a HelloSign callback
    # signature_request_all_signed
    # Store the signed document in Health Files and attach
    def post_completion_hook
      return unless all_signed?


    end

    #TDB: Hook to a HelloSign callback
    def refresh_signers!
      return if all_signed?
      # return false if self.hs_last_response.blank?

      self.hs_last_response_at = Time.now
      self.hs_last_response = hs_client.get_signature_request(signature_request_id: self.signature_request_id).data
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

    private

    def _signature_id_for(email)
      return nil if self.hs_initial_response.nil?

      res = Array.wrap(self.hs_initial_response['signatures']).find do |r|
        r['signer_email_address'] == email
      end

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
      @client ||= HelloSign::Client.new(api_key: ENV['HELLO_SIGN_API_KEY'])
    end

    def sane_number_signed
      return if signed_by.length <= signers.length

      errors[:signed_by] << "Cannot be longer than potential number of signers"
    end

  end
end
