# header
module Types
  class HmisSchema::Enums::MovingOnAssistance < Types::BaseEnum
    description 'C2.2'
    graphql_name 'MovingOnAssistance'
    value SUBSIDIZED_HOUSING_APPLICATION_ASSISTANCE, '(1) Subsidized housing application assistance', value: 1
    value FINANCIAL_ASSISTANCE_FOR_MOVING_ON_E_G_SECURITY_DEPOSIT_MOVING_EXPENSES, '(2) Financial assistance for Moving On (e.g., security deposit, moving expenses)', value: 2
    value NON_FINANCIAL_ASSISTANCE_FOR_MOVING_ON_E_G_HOUSING_NAVIGATION_TRANSITION_SUPPORT, '(3) Non-financial assistance for Moving On (e.g., housing navigation, transition support)', value: 3
    value HOUSING_REFERRAL_PLACEMENT, '(4) Housing referral/placement', value: 4
    value OTHER_PLEASE_SPECIFY, '(5) Other (please specify)', value: 5
  end
end
