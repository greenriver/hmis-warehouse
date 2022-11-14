# header
module Types
  class HmisSchema::Enums::SSVFSubType5 < Types::BaseEnum
    description 'V2.C'
    graphql_name 'SSVFSubType5'
    value PERSONAL_FINANCIAL_PLANNING_SERVICES, '(1) Personal financial planning services', value: 1
    value TRANSPORTATION_SERVICES, '(2) Transportation services', value: 2
    value INCOME_SUPPORT_SERVICES, '(3) Income support services', value: 3
    value FIDUCIARY_AND_REPRESENTATIVE_PAYEE_SERVICES, '(4) Fiduciary and representative payee services', value: 4
    value LEGAL_SERVICES_CHILD_SUPPORT, '(5) Legal services - child support', value: 5
    value LEGAL_SERVICES_EVICTION_PREVENTION, '(6) Legal services - eviction prevention', value: 6
    value LEGAL_SERVICES_OUTSTANDING_FINES_AND_PENALTIES, '(7) Legal services - outstanding fines and penalties', value: 7
    value LEGAL_SERVICES_RESTORE_ACQUIRE_DRIVER_S_LICENSE, "(8) Legal services - restore / acquire driver's license", value: 8
    value LEGAL_SERVICES_OTHER, '(9) Legal services - other', value: 9
    value CHILD_CARE, '(10) Child care', value: 10
    value HOUSING_COUNSELING, '(11) Housing counseling', value: 11
  end
end
