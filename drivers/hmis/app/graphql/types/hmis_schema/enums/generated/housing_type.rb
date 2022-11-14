# header
module Types
  class HmisSchema::Enums::HousingType < Types::BaseEnum
    description '2.8.8'
    graphql_name 'HousingType'
    value SITE_BASED_SINGLE_SITE, '(1) Site-based - single site', value: 1
    value SITE_BASED_CLUSTERED_MULTIPLE_SITES, '(2) Site-based - clustered / multiple sites', value: 2
    value TENANT_BASED_SCATTERED_SITE, '(3) Tenant-based - scattered site', value: 3
  end
end
