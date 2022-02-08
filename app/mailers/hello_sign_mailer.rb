###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HelloSignMailer < DatabaseMailer
  def careplan_signature_request(doc_id:, email:)
    @doc = Health::SignableDocument.where(id: doc_id)&.first
    # don't send if the request has already been canceled.
    return unless @doc.present?

    @hash  = @doc.signer_hash(email)
    @email = email

    mail(
      from: ENV.fetch('HEALTH_FROM'),
      to: @email,
      subject: 'Careplan Signature Requested',
    )
  end

  def pcp_signature_request(doc_id:, email:, name:, careplan_id:, client_id:)
    @doc = Health::SignableDocument.where(id: doc_id)&.first
    # don't send if the request has already been canceled.
    return unless @doc.present?

    @email = email
    @name = name
    @hash = @doc.signer_hash(email)
    @url = signature_client_health_careplan_signable_document_url(client_id: client_id, careplan_id: careplan_id, id: @doc.id, email: @email, hash: @hash)

    mail(
      from: ENV.fetch('HEALTH_FROM'),
      to: @email,
      subject: _('BH CP Request for Care Plan Signature'),
    )
  end

  def aco_signature_request(doc_id:, email:, name:, careplan_id:, client_id:)
    # We're really just using the signable document for the hash comparison feature
    @doc = Health::SignableDocument.where(id: doc_id)&.first
    # don't send if the request has already been canceled.
    return unless @doc.present?

    @request = @doc.signature_request
    return unless @request.present?

    @email = email
    @name = name
    @hash = @doc.signer_hash(email)
    @url = edit_client_health_careplan_aco_signature_request_url(client_id: client_id, careplan_id: careplan_id, id: @request.id, email: @email, hash: @hash)

    mail(
      from: ENV.fetch('HEALTH_FROM'),
      to: @email,
      subject: _('BH CP Request for Care Plan Signature'),
    )
  end
end
