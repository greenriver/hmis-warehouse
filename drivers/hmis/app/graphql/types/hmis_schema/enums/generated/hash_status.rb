# header
module Types
  class HmisSchema::Enums::HashStatus < Types::BaseEnum
    description '1.5'
    graphql_name 'HashStatus'
    value UNHASHED, '(1) Unhashed', value: 1
    value SHA_1_RHY, '(2) SHA-1 RHY', value: 2
    value HASHED_OTHER, '(3) Hashed - other', value: 3
    value SHA_256_RHY, '(4) SHA-256 (RHY)', value: 4
  end
end
