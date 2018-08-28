class HelloSignMailer < DatabaseMailer
  # TDB: maybe not a DatabaseMailer? I wouldn't think you would want to digest
  # this one
  # #TDB: Who should get cc'd or bcc'd?
  def careplan_signature_request(doc:, email:)
    @hash  = doc.signer_hash(email)
    @doc   = doc
    @email = email

    mail({
      to: @email,
      subject: "Careplan Signature Requested"
    })
  end

  def pcp_signature_request(doc:, email:, name:, careplan_id:, client_id: )
    @url = signature_client_health_careplan_signable_document_url(client_id: client_id, careplan_id: careplan_id, id: @doc.id, email: @email, hash: @hash)
    @doc = doc
    @email = email
    @name = name
    @hash = @doc.signer_hash(email)
  end
end
