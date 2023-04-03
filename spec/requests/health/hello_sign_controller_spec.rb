require 'rails_helper'

RSpec.describe HelloSignController, type: :request do
  let!(:provider) { create :provider }
  let!(:patient) { create :patient }
  let!(:careplan) { create :careplan, patient: patient, provider_id: provider.id }
  let!(:signable_document) { create :signable_careplan, signable_id: careplan.id }

  it 'accepts the HelloSign callback' do
    post hello_sign_path, params: { json: '' }

    expect(response.body).to eq('Hello API Event Received')
  end

  it 'does not sign document with invalid email' do
    post hello_sign_path, params: { json: '{"signature_request": {"metadata": {"data": {"signable_document_id": "' + signable_document.id.to_s + '"}}, ' \
      '"signatures": [{"status_code": "signed", "signer_email_address": "foo@bar.org", "signed_at": 1}]}}' }

    careplan.reload
    expect(signable_document.signed_by.blank?).to be true
  end

  it 'signs as patient with patient email' do
    post hello_sign_path, params: { json: '{"signature_request": {"metadata": {"data": {"signable_document_id": "' + signable_document.id.to_s + '"}}, ' \
      '"signatures": [{"status_code": "signed", "signer_email_address": "patient@openpath.biz", "signed_at": 1}]}}' }

    careplan.reload
    expect(careplan.patient_signed_on.present?).to be true
    expect(careplan.provider_signed_on.present?).to be false
  end

  it 'signs as provider with provider email' do
    post hello_sign_path, params: { json: '{"signature_request": {"metadata": {"data": {"signable_document_id": "' + signable_document.id.to_s + '"}}, ' \
      '"signatures": [{"status_code": "signed", "signer_email_address": "provider@openpath.biz", "signed_at": 1}]}}' }

    careplan.reload
    expect(careplan.provider_signed_on.present?).to be true
    expect(careplan.patient_signed_on.present?).to be false
  end

  # it 'is fully signed with both signatures' do
  #   post hello_sign_path, params: { json: '{"signature_request": {"metadata": {"data": {"signable_document_id": "' + signable_document.id.to_s + '"}}, ' \
  #     '"signatures": [{"status_code": "signed", "signer_email_address": "patient@openpath.biz", "signed_at": 1}]}}' }
  #
  #   post hello_sign_path, params: { json: '{"signature_request": {"metadata": {"data": {"signable_document_id": "' + signable_document.id.to_s + '"}}, ' \
  #     '"signatures": [{"status_code": "signed", "signer_email_address": "provider@openpath.biz", "signed_at": 1}]}}' }
  #
  #   expect(Health::Careplan.fully_signed.where(id: careplan.id).exists?).to be true
  # end
end
