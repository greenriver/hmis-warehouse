# header
module Types
  class HmisSchema::Enums::ReferralSource < Types::BaseEnum
    description 'R1.1'
    graphql_name 'ReferralSource'
    value SELF_REFERRAL, '(1) Self-referral', value: 1
    value INDIVIDUAL_PARENT_GUARDIAN_RELATIVE_FRIEND_FOSTER_PARENT_OTHER_INDIVIDUAL, '(2) Individual: Parent/Guardian/Relative/Friend/Foster Parent/Other Individual', value: 2
    value OUTREACH_PROJECT, '(7) Outreach Project', value: 7
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value OUTREACH_PROJECT_OTHER, '(10) Outreach project: other', value: 10
    value TEMPORARY_SHELTER, '(11) Temporary Shelter', value: 11
    value RESIDENTIAL_PROJECT, '(18) Residential Project', value: 18
    value HOTLINE, '(28) Hotline', value: 28
    value CHILD_WELFARE_CPS, '(30) Child Welfare/CPS', value: 30
    value JUVENILE_JUSTICE, '(34) Juvenile Justice', value: 34
    value LAW_ENFORCEMENT_POLICE, '(35) Law Enforcement/ Police', value: 35
    value MENTAL_HOSPITAL, '(37) Mental Hospital', value: 37
    value SCHOOL, '(38) School', value: 38
    value OTHER_ORGANIZATION, '(39) Other organization', value: 39
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
