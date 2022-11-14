# header
module Types
  class HmisSchema::Enums::SubsidyInformation < Types::BaseEnum
    description 'W5.A'
    graphql_name 'SubsidyInformation'
    value WITHOUT_A_SUBSIDY_1, '(1) Without a subsidy 1', value: 1
    value WITH_THE_SUBSIDY_THEY_HAD_AT_PROJECT_ENTRY_1, '(2) With the subsidy they had at project entry 1', value: 2
    value WITH_AN_ON_GOING_SUBSIDY_ACQUIRED_SINCE_PROJECT_ENTRY_1, '(3) With an on-going subsidy acquired since project entry 1', value: 3
    value BUT_ONLY_WITH_OTHER_FINANCIAL_ASSISTANCE_1, '(4) But only with other financial assistance 1', value: 4
    value WITH_ON_GOING_SUBSIDY_2, '(11) With on-going subsidy 2', value: 11
    value WITHOUT_AN_ON_GOING_SUBSIDY_2, '(12) Without an on-going subsidy 2', value: 12
  end
end
