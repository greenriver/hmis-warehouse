# header
module Types
  class HmisSchema::Enums::HOPWAServices < Types::BaseEnum
    description 'W1.2'
    graphql_name 'HOPWAServices'
    value ADULT_DAY_CARE_AND_PERSONAL_ASSISTANCE, '(1) Adult day care and personal assistance', value: 1
    value CASE_MANAGEMENT, '(2) Case management', value: 2
    value CHILD_CARE, '(3) Child care', value: 3
    value CRIMINAL_JUSTICE_LEGAL_SERVICES, '(4) Criminal justice/legal services', value: 4
    value EDUCATION, '(5) Education', value: 5
    value EMPLOYMENT_AND_TRAINING_SERVICES, '(6) Employment and training services', value: 6
    value FOOD_MEALS_NUTRITIONAL_SERVICES, '(7) Food/meals/nutritional services', value: 7
    value HEALTH_MEDICAL_CARE, '(8) Health/medical care', value: 8
    value LIFE_SKILLS_TRAINING, '(9) Life skills training', value: 9
    value MENTAL_HEALTH_CARE_COUNSELING, '(10) Mental health care/counseling', value: 10
    value OUTREACH_AND_OR_ENGAGEMENT, '(11) Outreach and/or engagement', value: 11
    value SUBSTANCE_ABUSE_SERVICES_TREATMENT, '(12) Substance abuse services/treatment', value: 12
    value TRANSPORTATION, '(13) Transportation', value: 13
    value OTHER_HOPWA_FUNDED_SERVICE, '(14) Other HOPWA funded service', value: 14
  end
end
