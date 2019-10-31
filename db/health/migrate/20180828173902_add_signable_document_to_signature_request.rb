class AddSignableDocumentToSignatureRequest < ActiveRecord::Migration[4.2]
  def change
    add_reference :signature_requests, :signable_document
  end
end
