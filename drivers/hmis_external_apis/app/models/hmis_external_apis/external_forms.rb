module HmisExternalApis::ExternalForms
  def external_forms_shared_key
    GrdaWarehouse::RemoteCredentials::SymmetricEncryptionKey.where(slug: 'external_forms_shared_key').first
  end
end
