# header
module Types
  class HmisSchema::Enums::RecordType < Types::BaseEnum
    description '1.4'
    graphql_name 'RecordType'
    value CONTACT, '(12) Contact', value: 12
    value CONTACT, '(13) Contact', value: 13
    value PATH_SERVICE, '(141) PATH service', value: 141
    value RHY_SERVICE_CONNECTIONS, '(142) RHY service connections', value: 142
    value HOPWA_SERVICE, '(143) HOPWA service', value: 143
    value SSVF_SERVICE, '(144) SSVF service', value: 144
    value HOPWA_FINANCIAL_ASSISTANCE, '(151) HOPWA financial assistance', value: 151
    value SSVF_FINANCIAL_ASSISTANCE, '(152) SSVF financial assistance', value: 152
    value PATH_REFERRAL, '(161) PATH referral', value: 161
    value RHY_REFERRAL, '(162) RHY referral', value: 162
    value BED_NIGHT, '(200) Bed night', value: 200
    value HUD_VASH_OTH_VOUCHER_TRACKING, '(210) HUD-VASH OTH voucher tracking', value: 210
    value C2_MOVING_ON_ASSISTANCE_PROVIDED, '(300) C2 Moving On Assistance Provided', value: 300
  end
end
