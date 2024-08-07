###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class HudAssessmentFormRules2024
    # Keys match Link IDs in our default HUD Assessments.
    #
    # KNOWN HUD COMPLIANCE ISSUES:
    # - W4 (part of hopwa_disability) should enforce compliance at Annual data collection stage (GH#6463)

    HUD_LINK_ID_RULES = {
      q_4_11: { stages: ['INTAKE', 'UPDATE'],
                data_collected_about: 'HOH_AND_ADULTS',
                rule: { 'operator' => 'ANY',
                        'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
                     ] },
          { '_comment' => 'HUD: ESG – Collection required for all components ',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: ESG' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
          [
            { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
          ] },
          { '_comment' => 'HUD: HOPWA – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HOPWA' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
          [
            { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
          ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
          [
            { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Rural Special NOFO' },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
            { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
          ] },
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: PFS – Collection required for all permanent housing projects',
            'parts' =>
          [
            { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: PFS' },
            { 'operator' => 'ANY',
              'parts' =>
            [
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 9 },
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 10 },
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
            ] },
          ] },
          { '_comment' => 'HHS: PATH – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: PATH' },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
          [
            { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
            { 'operator' => 'ANY',
              'parts' =>
            [
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
            ] },
          ] },
          { '_comment' => 'VA: GPD – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
          { '_comment' => 'VA: Community Contract Safe Haven', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 30 },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
          { '_comment' => 'YHDP', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 },
        ] } },
      c3_youth_education_status: { stages: ['INTAKE', 'EXIT'],
                                   data_collected_about: 'HOH',
                                   rule: { 'operator' => 'ALL',
                                           '_comment' => 'YHDP-funded program should collect this instead of R5',
                                           'parts' => [{ 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 }] } },
      C4_group: { stages: ['INTAKE'],
                  data_collected_about: 'HOH',
                  rule: { 'operator' => 'ANY',
                          'parts' =>
        [
          { '_comment' => 'HUD: CoC – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: CoC' },
          { '_comment' => 'HUD: ESG – Collection required for all components ',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: ESG' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: Unsheltered Special NOFO' },
          { '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 55 },
        ] } },
      destination: { stages: ['EXIT'], data_collected_about: 'ALL_CLIENTS', rule: nil },
      # 3.08 disabling condition
      disability: { stages: ['INTAKE'], data_collected_about: 'ALL_CLIENTS', rule: nil },
      # 4.08 hiv aids
      disability_table_r4: { stages: ['INTAKE', 'UPDATE', 'EXIT'],
                             data_collected_about: 'ALL_CLIENTS',
                             rule: { 'operator' => 'ANY',
                                     'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
                     ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG – Collection required for all components except ES-NbN',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'HUD: HOPWA – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HOPWA' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 55 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 20 },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: PFS – Collection required for all permanent housing projects',
            'parts' =>
            [
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 35 },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 9 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 10 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'VA: GPD – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
          { '_comment' => 'VA: Community Contract Safe Haven', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 30 },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
          { '_comment' => 'YHDP', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 },
        ] } },
      disability_table: { stages: ['INTAKE', 'UPDATE', 'EXIT'],
                          data_collected_about: 'ALL_CLIENTS',
                          rule: { 'operator' => 'ANY',
                                  'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
                     ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG – Collection required for all components except ES-NbN',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'HUD: HOPWA – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HOPWA' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 55 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: PFS – Collection required for all permanent housing projects',
            'parts' =>
            [
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 35 },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 9 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 10 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'HHS: PATH – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: PATH' },
          { '_comment' => 'HHS: RHY – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: RHY' },
          { '_comment' => 'VA: GPD – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
          { '_comment' => 'VA: Community Contract Safe Haven',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: Community Contract Safe Haven' },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
          { '_comment' => 'YHDP', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 },
        ] } },
      # enrollment coc
      q_3_16: { stages: ['INTAKE'], data_collected_about: 'HOH', rule: nil },
      health_insurance: { stages: ['INTAKE', 'UPDATE', 'ANNUAL', 'EXIT'],
                          data_collected_about: 'ALL_CLIENTS',
                          rule: { 'operator' => 'ANY',
                                  'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
                     ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG – Collection required for all components except ES-NbN',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'HUD: HOPWA – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HOPWA' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Rural Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: PFS – Collection required for all permanent housing projects',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: PFS' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 9 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 10 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'HHS: PATH – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: PATH' },
          { '_comment' => 'HHS: RHY – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: RHY' },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'VA: GPD – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
          { '_comment' => 'VA: Community Contract Safe Haven', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 30 },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
          { '_comment' => 'YHDP', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 },
        ] } },
      income_and_sources: { stages: ['INTAKE', 'UPDATE', 'ANNUAL', 'EXIT'],
                            data_collected_about: 'HOH_AND_ADULTS',
                            rule: { 'operator' => 'ANY',
                                    'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
                     ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG – Collection required for all components except ES-NbN',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'HUD: HOPWA – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HOPWA' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Rural Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: PFS – Collection required for all permanent housing projects',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: PFS' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 9 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 10 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'HHS: PATH – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: PATH' },
          { '_comment' => 'HHS: RHY – Collection only required for MGH, TLP, and Demo',
            'operator' => 'ANY',
            'parts' =>
            [
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 23 },
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 24 },
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 26 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'VA: GPD – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
          { '_comment' => 'VA: Community Contract Safe Haven', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 30 },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
          { '_comment' => 'YHDP', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 },
        ] } },
      non_cash_benefits: { stages: ['INTAKE', 'UPDATE', 'ANNUAL', 'EXIT'],
                           data_collected_about: 'HOH_AND_ADULTS',
                           rule: { 'operator' => 'ANY',
                                   'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
                     ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG – Collection required for all components except ES-NbN',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'HUD: HOPWA – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HOPWA' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Rural Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 6 },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 14 },
            ] },
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: PFS – Collection required for all permanent housing projects',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: PFS' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 9 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 10 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'HHS: PATH – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: PATH' },
          { '_comment' => 'HHS: RHY – Collection only required for BCP (HP and ES), MGH, TLP, and Demo',
            'operator' => 'ANY',
            'parts' =>
            [
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 22 },
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 23 },
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 24 },
              { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 26 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'VA: GPD – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
          { '_comment' => 'VA: Community Contract Safe Haven', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 30 },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
          { '_comment' => 'YHDP', 'variable' => 'projectFunders', 'operator' => 'INCLUDE', 'value' => 43 },
        ] } },
      P4_1: { stages: ['INTAKE', 'UPDATE', 'ANNUAL', 'EXIT'],
              data_collected_about: 'HOH_AND_ADULTS',
              rule: { 'operator' => 'ANY',
                      'parts' =>
        [
          { '_comment' => 'HHS: PATH – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: PATH' },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
        ] } },
      q_3_917A: { stages: ['INTAKE'],
                  data_collected_about: 'HOH_AND_ADULTS',
                  rule: { 'operator' => 'ANY',
                          'parts' =>
        [
          { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 0 },
          { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 1 },
          { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 4 },
          { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 8 },
        ] } },
      q_3_917B: { stages: ['INTAKE'],
                  data_collected_about: 'HOH_AND_ADULTS',
                  rule: { 'operator' => 'ALL',
                          'parts' =>
        [
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 0 },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 1 },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 8 },
        ] } },
      R10: { stages: ['INTAKE', 'UPDATE'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ANY',
                     'parts' =>
        [
          { '_comment' => 'HHS: RHY – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: RHY' },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      R11: { stages: ['INTAKE'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ANY',
                     'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
                     ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      R12: { stages: ['INTAKE'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ANY',
                     'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
                     ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      family_critical_issues: { stages: ['INTAKE'],
                                data_collected_about: 'HOH_AND_ADULTS',
                                rule: { 'operator' => 'ALL',
                                        '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
                                        'parts' =>
        [
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
        ] } },
      R15: { stages: ['EXIT'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { '_comment' => 'HHS: RHY – Collection required for all components',
                     'variable' => 'projectFunderComponents',
                     'operator' => 'INCLUDE',
                     'value' => 'HHS: RHY' } },
      R16: { stages: ['EXIT'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { '_comment' => 'HHS: RHY – Collection required for all components',
                     'variable' => 'projectFunderComponents',
                     'operator' => 'INCLUDE',
                     'value' => 'HHS: RHY' } },
      R17: { stages: ['EXIT'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ANY',
                     'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach and BCP-Prevention',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', '_comment' => 'street outreach', 'value' => 4 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', '_comment' => 'prevention', 'value' => 12 },
                     ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      R18: { stages: ['EXIT'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ALL',
                     '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
                     'parts' =>
        [
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
        ] } },
      R19: { stages: ['EXIT'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ANY',
                     'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' =>
                     'HHS: RHY – Collection required for all components except for Street Outreach and Homelessness Prevention',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 12 },
                     ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      R1: { stages: ['INTAKE'],
            data_collected_about: 'HOH_AND_ADULTS',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'variable' => 'projectFunders', 'operator' => 'INCLUDE', '_comment' => 'All YHDP', 'value' => 43 },
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
        ] } },
      R20: { stages: ['POST_EXIT'],
             data_collected_about: 'HOH_AND_ADULTS',
             rule: { 'operator' => 'ALL',
                     '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
                     'parts' =>
        [
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
        ] } },
      R2: { stages: ['INTAKE'],
            data_collected_about: 'ALL_CLIENTS',
            rule: { '_comment' => 'HHS: RHY – Collection required for BCP only',
                    'variable' => 'projectFunders',
                    'operator' => 'INCLUDE',
                    'value' => 22 } },
      R3: { stages: ['INTAKE'],
            data_collected_about: 'HOH_AND_ADULTS',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { '_comment' => 'HUD: CoC – Youth Homeless Demonstration Program (YHDP) – collection required for all components',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
          { '_comment' => 'HHS: RHY – Collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HHS: RHY' },
          { '_comment' => 'HUD: CoC – Permanent Supportive Housing',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 2 },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Unsheltered Special NOFO – Collection required for Permanent Supportive Housing',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Unsheltered Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: Rural Special NOFO – Collection required for Permanent Supportive Housing',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: Rural Special NOFO' },
              { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
            ] },
        ] } },
      R4: { stages: ['INTAKE', 'EXIT'],
            data_collected_about: nil,
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { '_comment' => 'HUD: HUD-VASH – – Collection required for HUD/VASH- Continuum',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                '_comment' => 'RRH or HP',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
        ] } },
      R5: { stages: ['INTAKE', 'EXIT'],
            data_collected_about: nil,
            rule: { 'operator' => 'ALL',
                    '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
                    'parts' =>
        [
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
          { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
        ] } },
      R6: { stages: ['INTAKE', 'EXIT'],
            data_collected_about: nil,
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { '_comment' => 'HUD: HUD-VASH – – Collection required for HUD/VASH- Continuum',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                '_comment' => 'RRH or HP',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { '_comment' => 'VA: GPD – collection required for all components',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'VA: GPD' },
        ] } },
      R7: { stages: ['INTAKE', 'EXIT'],
            data_collected_about: nil,
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD/VASH-Continuum',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
              { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
            ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      rhy_health_status: { stages: [], data_collected_about: 'HOH_AND_ADULTS', rule: nil },
      R8: { stages: ['INTAKE', 'EXIT'],
            data_collected_about: nil,
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
                     ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      R9: { stages: ['INTAKE', 'EXIT'],
            data_collected_about: nil,
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'HHS: RHY – Collection required for all components except for Street Outreach',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HHS: RHY' },
                       { 'variable' => 'projectType', 'operator' => 'NOT_EQUAL', 'value' => 4 },
                     ] },
          { '_comment' => 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
            'variable' => 'projectFunders',
            'operator' => 'INCLUDE',
            'value' => 43 },
        ] } },
      V4: { stages: ['INTAKE'],
            data_collected_about: 'HOH',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
                       { 'operator' => 'ANY',
                         'parts' =>
                         [
                           { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                           { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                         ] },
                     ] },
        ] } },
      V6: { stages: ['INTAKE'],
            data_collected_about: 'HOH',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: HUD-VASH' },
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 13 },
                ] },
            ] },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: GPD' },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: Community Contract Safe Haven' },
          { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: CRS Contract Residential Services' },
        ] } },
      V7: { stages: ['INTAKE'],
            data_collected_about: 'HOH',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' => 'VA: SSVF – Collection required for Homelessness Prevention',
            'parts' =>
                     [
                       { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'VA: SSVF' },
                       { 'operator' => 'ANY', 'parts' => [{ 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 }] },
                     ] },
        ] } },
      V9: { stages: ['EXIT'],
            data_collected_about: 'HOH',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { '_comment' => 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
            'variable' => 'projectFunderComponents',
            'operator' => 'INCLUDE',
            'value' => 'HUD: HUD-VASH' },
        ] } },
      # W3
      medical_assistance: { stages: ['INTAKE', 'UPDATE', 'EXIT'],
                            data_collected_about: 'ALL_CLIENTS',
                            rule: { '_comment' => 'HUD: HOPWA – Collection required for all components',
                                    'variable' => 'projectFunderComponents',
                                    'operator' => 'INCLUDE',
                                    'value' => 'HUD: HOPWA' } },
      # w4 and w6
      # FIXME: w4 is required at annual, but not currently collected there. that should be addressed. it is this was because disability is otherwise not collected at annual
      hopwa_disability: { stages: ['INTAKE', 'UPDATE', 'EXIT'],
                          data_collected_about: nil,
                          rule: { 'operator' => 'ALL', 'parts' => [{ 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: HOPWA' }] } },
      W5: { stages: ['EXIT'],
            data_collected_about: 'ALL_CLIENTS',
            rule: { 'operator' => 'ANY',
                    'parts' =>
        [
          { 'operator' => 'ALL',
            '_comment' =>
                     'HUD: CoC – Collection required only for Homelessness Prevention component; HUD: ESG – Collection required only for Homelessness Prevention component; HUD: ESG-RUSH – Collection required for Homelessness Prevention component',
            'parts' =>
                     [
                       { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                       { 'operator' => 'ANY',
                         'parts' =>
                         [
                           { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: CoC' },
                           { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG' },
                           { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: ESG RUSH' },
                         ] },
                     ] },
          { 'operator' => 'ALL',
            '_comment' => 'HUD: HOPWA – Collection required for all components',
            'parts' =>
            [
              { 'variable' => 'projectFunderComponents', 'operator' => 'INCLUDE', 'value' => 'HUD: HOPWA' },
              { 'operator' => 'ANY',
                'parts' =>
                [
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 0 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 2 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 3 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 6 },
                  { 'variable' => 'projectType', 'operator' => 'EQUAL', 'value' => 12 },
                ] },
            ] },
        ] } },
    }.freeze

    # Returns Hash{ role => Set<link id> }
    def role_to_link_ids
      @role_to_link_ids ||= HUD_LINK_ID_RULES.each_with_object({}) do |(link_id, config), hash|
        config[:stages].each do |role|
          hash[role] ||= Set.new
          hash[role].add(link_id.to_s)
        end
      end
    end

    def hud_data_element?(form_role, link_id)
      HUD_LINK_ID_RULES.key?(link_id.to_sym) && HUD_LINK_ID_RULES[link_id.to_sym][:stages].include?(form_role.to_s)
    end

    def hud_data_element_rule(form_role, link_id)
      return unless hud_data_element?(form_role.to_s, link_id.to_sym)

      HUD_LINK_ID_RULES[link_id.to_sym][:rule]
    end

    def hud_data_element_data_collected_about(form_role, link_id)
      return unless hud_data_element?(form_role.to_s, link_id.to_sym)

      HUD_LINK_ID_RULES[link_id.to_sym][:data_collected_about]
    end

    def required_link_ids_for_role(role)
      role_to_link_ids[role.to_s] || []
    end
  end
end
