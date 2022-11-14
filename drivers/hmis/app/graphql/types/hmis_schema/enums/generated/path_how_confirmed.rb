# header
module Types
  class HmisSchema::Enums::PATHHowConfirmed < Types::BaseEnum
    description '4.9.D'
    graphql_name 'PATHHowConfirmed'
    value UNCONFIRMED_PRESUMPTIVE_OR_SELF_REPORT, '(1) Unconfirmed; presumptive or self-report', value: 1
    value CONFIRMED_THROUGH_ASSESSMENT_AND_CLINICAL_EVALUATION, '(2) Confirmed through assessment and clinical evaluation', value: 2
    value CONFIRMED_BY_PRIOR_EVALUATION_OR_CLINICAL_RECORDS, '(3) Confirmed by prior evaluation or clinical records', value: 3
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
