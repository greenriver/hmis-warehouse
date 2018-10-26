# This is a stub model that maps to the PatientReferral table.
# It is only used for importing refresh files, which have a different shape from
# the normal referral files
module Health
  class PatientReferralRefresh < HealthBase
    include PatientReferralRefreshImporter
    include ArelHelper
    self.table_name = :patient_referrals

  end
end