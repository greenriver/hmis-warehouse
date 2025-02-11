###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    belongs_to :signable, polymorphic: true, optional: true
    # belongs_to :health_file, dependent: :destroy, class_name: 'Health::SignableDocumentFile', optional: true
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

    EMAIL_REGEX = /[\w.+]+@[\w.+]+/

    def self.patient_expiration_window
      1.hours.from_now
    end

    def expired?
      expires_at.blank? || expires_at < Time.now
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

    def signed_on(email)
      signature = hs_last_response['signatures'].
        find { |sig| opt_data(sig)['status_code'] == 'signed' && opt_data(sig)['signer_email_address']&.downcase == email.downcase }

      timestamp = opt_data(signature)['signed_at'] if signature.present?

      return nil unless timestamp.present?

      Time.at(timestamp)
    end

    private def opt_data(json)
      json&.dig('data') || json
    end
  end
end
