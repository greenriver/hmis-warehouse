# header
module Types
  class HmisSchema::Enums::BedType < Types::BaseEnum
    description '2.7.3'
    graphql_name 'BedType'
    value FACILITY_BASED, '(1) Facility-based', value: 1
    value VOUCHER, '(2) Voucher', value: 2
    value OTHER, '(3) Other', value: 3
  end
end
