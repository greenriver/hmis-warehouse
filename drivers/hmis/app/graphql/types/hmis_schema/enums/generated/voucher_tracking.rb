# header
module Types
  class HmisSchema::Enums::VoucherTracking < Types::BaseEnum
    description 'V8.1'
    graphql_name 'VoucherTracking'
    value REFERRAL_PACKAGE_FORWARDED_TO_PHA, '(1) Referral package forwarded to PHA', value: 1
    value VOUCHER_DENIED_BY_PHA, '(2) Voucher denied by PHA', value: 2
    value VOUCHER_ISSUED_BY_PHA, '(3) Voucher issued by PHA', value: 3
    value VOUCHER_REVOKED_OR_EXPIRED, '(4) Voucher revoked or expired', value: 4
    value VOUCHER_IN_USE_VETERAN_MOVED_INTO_HOUSING, '(5) Voucher in use - veteran moved into housing', value: 5
    value VOUCHER_WAS_PORTED_LOCALLY, '(6) Voucher was ported locally', value: 6
    value VOUCHER_WAS_ADMINISTRATIVELY_ABSORBED_BY_NEW_PHA, '(7) Voucher was administratively absorbed by new PHA', value: 7
    value VOUCHER_WAS_CONVERTED_TO_HOUSING_CHOICE_VOUCHER, '(8) Voucher was converted to Housing Choice Voucher', value: 8
    value VETERAN_EXITED_VOUCHER_WAS_RETURNED, '(9) Veteran exited - voucher was returned', value: 9
    value VETERAN_EXITED_FAMILY_MAINTAINED_THE_VOUCHER, '(10) Veteran exited - family maintained the voucher', value: 10
    value VETERAN_EXITED_PRIOR_TO_EVER_RECEIVING_A_VOUCHER, '(11) Veteran exited - prior to ever receiving a voucher', value: 11
    value OTHER, '(12) Other', value: 12
  end
end
