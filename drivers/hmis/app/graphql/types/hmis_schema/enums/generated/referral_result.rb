# header
module Types
  class HmisSchema::Enums::ReferralResult < Types::BaseEnum
    description '4.20.D'
    graphql_name 'ReferralResult'
    value SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED, '(1) Successful referral: client accepted', value: 1
    value UNSUCCESSFUL_REFERRAL_CLIENT_REJECTED, '(2) Unsuccessful referral: client rejected', value: 2
    value UNSUCCESSFUL_REFERRAL_PROVIDER_REJECTED, '(3) Unsuccessful referral: provider rejected', value: 3
  end
end
