# header
module Types
  class HmisSchema::Enums::TargetPopulation < Types::BaseEnum
    description '2.9.1'
    graphql_name 'TargetPopulation'
    value DOMESTIC_VIOLENCE_VICTIMS, '(1) Domestic violence victims', value: 1
    value PERSONS_WITH_HIV_AIDS, '(3) Persons with HIV/AIDS', value: 3
    value NOT_APPLICABLE, '(4) Not applicable', value: 4
  end
end
