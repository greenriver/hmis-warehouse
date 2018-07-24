module Health
  class MemberStatusReportPatient < HealthBase
    acts_as_paranoid
    belongs_to :member_status_report
    has_one :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_one :patient_referral, through: :patient

  end
end