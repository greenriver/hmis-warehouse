###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class HudFormRules2022
    # Keys match Link IDs in our Form Definition fragments for HUD data elements
    HUD_LINK_ID_RULES = {
      # Prior Living Situation A
      q_3_917A: {
        # Data Collection Stages you are required to collect per HUD (only required if rule matches)
        stages: [:INTAKE],
        # Client groups you are required to collect about per HUD (only required if rule matches)
        data_collected_about: :HOH_AND_ADULTS,
        # Project/Funders required to collect, per HUD
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "variable": 'projectType',
              "operator": 'EQUAL',
              "value": 0,
            },
            {
              "variable": 'projectType',
              "operator": 'EQUAL',
              "value": 1,
            },
            {
              "variable": 'projectType',
              "operator": 'EQUAL',
              "value": 4,
            },
            {
              "variable": 'projectType',
              "operator": 'EQUAL',
              "value": 8,
            },
          ],
        },
      },
      # Prior Living Situation B
      q_3_917B: {
        stages: [:INTAKE],
        data_collected_about: :HOH_AND_ADULTS,
        rule: {
          "operator": 'ALL',
          "parts": [
            {
              "variable": 'projectType',
              "operator": 'NOT_EQUAL',
              "value": 0,
            },
            {
              "variable": 'projectType',
              "operator": 'NOT_EQUAL',
              "value": 1,
            },
            {
              "variable": 'projectType',
              "operator": 'NOT_EQUAL',
              "value": 4,
            },
            {
              "variable": 'projectType',
              "operator": 'NOT_EQUAL',
              "value": 8,
            },
          ],
        },
      },
      health_insurance: {
        stages: [:INTAKE, :UPDATE, :ANNUAL, :EXIT],
        data_collected_about: :ALL_CLIENTS,
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "operator": 'ALL',
              "_comment": 'HUD: CoC – Collection required for all components except SSO Coordinated Entry',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: CoC',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 6,
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 14,
                },
              ],
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: ESG – Collection required for all components except ES-NbN',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: ESG',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 1,
                },
              ],
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: ESG RUSH – Collection required for all components except Emergency Shelter or Street Outreach',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: ESG RUSH',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 0,
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 1,
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 4,
                },
              ],
            },
            {
              "_comment": 'HUD: HOPWA – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HUD: HOPWA',
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: Unsheltered Special NOFO – Collection required for all components except SSO Coordinated Entry',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: Unsheltered Special NOFO',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 6,
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 14,
                },
              ],
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: Rural Special NOFO',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 6,
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 14,
                },
              ],
            },
            {
              "_comment": 'HUD: HUD-VASH – Collection required for HUD VASH Collaborative Case Management',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HUD: HUD-VASH',
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: PFS – Collection required for all permanent housing projects',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: PFS',
                },
                {
                  "operator": 'ANY',
                  "parts": [
                    {
                      "variable": 'projectType',
                      "operator": 'EQUAL',
                      "value": 3,
                    },
                    {
                      "variable": 'projectType',
                      "operator": 'EQUAL',
                      "value": 9,
                    },
                    {
                      "variable": 'projectType',
                      "operator": 'EQUAL',
                      "value": 10,
                    },
                    {
                      "variable": 'projectType',
                      "operator": 'EQUAL',
                      "value": 13,
                    },
                  ],
                },
              ],
            },
            {
              "_comment": 'HHS: PATH – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HHS: PATH',
            },
            {
              "_comment": 'HHS: RHY – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HHS: RHY',
            },
            {
              "operator": 'ALL',
              "_comment": 'VA: SSVF – Collection required for RRH and Homelessness Prevention',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'VA: SSVF',
                },
                {
                  "operator": 'ANY',
                  "parts": [
                    {
                      "variable": 'projectType',
                      "operator": 'EQUAL',
                      "value": 12,
                    },
                    {
                      "variable": 'projectType',
                      "operator": 'EQUAL',
                      "value": 13,
                    },
                  ],
                },
              ],
            },
            {
              "_comment": 'VA: GPD – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'VA: GPD',
            },
            {
              "_comment": 'VA: Community Contract Safe Haven',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 30,
            },
            {
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'VA: CRS Contract Residential Services',
            },
            {
              "_comment": 'YHDP',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 43,
            },
          ],
        },
      },
    }.freeze

    def hud_data_element?(form_role, link_id)
      HUD_LINK_ID_RULES.key?(link_id) && HUD_LINK_ID_RULES[link_id][:stages].include?(form_role)
    end

    def hud_data_element_rule(form_role, link_id)
      return unless hud_data_element?(form_role, link_id)

      HUD_LINK_ID_RULES[link_id][:rule]
    end
  end
end
