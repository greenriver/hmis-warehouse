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
end
