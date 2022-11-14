# header
module Types
  class HmisSchema::Enums::CmExitReason < Types::BaseEnum
    description 'V9.1'
    graphql_name 'CmExitReason'
    value ACCOMPLISHED_GOALS_AND_OR_OBTAINED_SERVICES_AND_NO_LONGER_NEEDS_CM, '(1) Accomplished goals and/or obtained services and no longer needs CM', value: 1
    value TRANSFERRED_TO_ANOTHER_HUD_VASH_PROGRAM_SITE, '(2) Transferred to another HUD/VASH program site', value: 2
    value FOUND_CHOSE_OTHER_HOUSING, '(3) Found/chose other housing', value: 3
    value DID_NOT_COMPLY_WITH_HUD_VASH_CM, '(4) Did not comply with HUD/VASH CM', value: 4
    value EVICTION_AND_OR_OTHER_HOUSING_RELATED_ISSUES, '(5) Eviction and/or other housing related issues', value: 5
    value UNHAPPY_WITH_HUD_VASH_HOUSING, '(6) Unhappy with HUD/VASH housing', value: 6
    value NO_LONGER_FINANCIALLY_ELIGIBLE_FOR_HUD_VASH_VOUCHER, '(7) No longer financially eligible for HUD/VASH voucher', value: 7
    value NO_LONGER_INTERESTED_IN_PARTICIPATING_IN_THIS_PROGRAM, '(8) No longer interested in participating in this program', value: 8
    value VETERAN_CANNOT_BE_LOCATED, '(9) Veteran cannot be located', value: 9
    value VETERAN_TOO_ILL_TO_PARTICIPATE_AT_THIS_TIME, '(10) Veteran too ill to participate at this time', value: 10
    value VETERAN_IS_INCARCERATED, '(11) Veteran is incarcerated', value: 11
    value VETERAN_IS_DECEASED, '(12) Veteran is deceased', value: 12
    value OTHER, '(13) Other', value: 13
  end
end
