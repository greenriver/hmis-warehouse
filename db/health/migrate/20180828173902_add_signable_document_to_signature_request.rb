class AddSignableDocumentToSignatureRequest < ActiveRecord::Migration
  def change
    add_reference :signature_requests, :signable_document
  end
end
