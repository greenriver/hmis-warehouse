module ClaimsReporting
  class CpPaymentDetail < HealthBase
    belongs_to :cp_payment_upload,
               required: true,
               class_name: 'ClaimsReporting::CpPaymentUpload',
               inverse_of: :details

    belongs_to :patient,
               required: false, # these may not match up 100%
               class_name: 'Health::Patient',
               primary_key: :medicaid_id,
               foreign_key: :medicaid_id

    validates :medicaid_id, presence: true
  end
end
