# header
module Types
  class HmisSchema::Enums::AnnualPercentAMI < Types::BaseEnum
    description 'V7.B'
    graphql_name 'AnnualPercentAMI'
    value NUM_0_I_E_NOT_EMPLOYED_NOT_RECEIVING_CASH_BENEFITS_NO_OTHER_CURRENT_INCOME, '(0) $0 (i.e., not employed, not receiving cash benefits, no other current income)', value: 0
    value NUM_1_14_OF_AREA_MEDIAN_INCOME_AMI_FOR_HOUSEHOLD_SIZE, '(1) 1-14% of Area Median Income (AMI) for household size', value: 1
    value NUM_15_30_OF_AMI_FOR_HOUSEHOLD_SIZE, '(2) 15-30% of AMI for household size', value: 2
    value MORE_THAN_30_OF_AMI_FOR_HOUSEHOLD_SIZE, '(3) More than 30% of AMI for household size', value: 3
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
