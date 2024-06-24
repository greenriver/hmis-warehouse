###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class HudAssessmentFormRules2024
    # Keys match Link IDs in our default HUD Assessments.
    # Doesn't feel ideal to key off Link ID since it's meant to be internal to the form, but we are avoiding
    # adding a new field to the form.
    HUD_LINK_ID_RULES = {
      # CoC Code for Client Location
      q_3_16: {
        stages: [:INTAKE],
        data_collected_about: :HOH,
      },
      # r1_referral_source
      R1: {
        stages: [:INTAKE],
        data_collected_about: :HOH_AND_ADULTS,
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "_comment": 'All YHDP',
              "value": 43,
            },
            {
              "operator": 'ALL',
              "_comment": 'HHS: RHY – Collection required for all components except for Street Outreach',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HHS: RHY',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 4,
                },
              ],
            },
          ],
        },
      },
      # c4_translation_assistance
      C4_group: {
        stages: [:INTAKE],
        data_collected_about: :HOH,
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "_comment": 'HUD: CoC – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HUD: CoC',
            },
            {
              "_comment": 'HUD: ESG – Collection required for all components ',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HUD: ESG',
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
              "_comment": 'HUD: Unsheltered Special NOFO – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HUD: Unsheltered Special NOFO',
            },
            {
              "_comment": 'HUD: Rural Special NOFO – Collection required for all components except SSO Coordinated Entry',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 55,
            },
          ],
        },
      },
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
      # r3_sexual_orientation
      R3: {
        stages: [:INTAKE],
        data_collected_about: :HOH_AND_ADULTS,
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "_comment": 'HUD: CoC – Youth Homeless Demonstration Program (YHDP) – collection required for all components',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 43,
            },
            {
              "_comment": 'HHS: RHY – Collection required for all components',
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HHS: RHY',
            },
            {
              "_comment": 'HUD: CoC – Permanent Supportive Housing',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 2,
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: Unsheltered Special NOFO – Collection required for Permanent Supportive Housing',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: Unsheltered Special NOFO',
                },
                {
                  "variable": 'projectType',
                  "operator": 'EQUAL',
                  "value": 3,
                },
              ],
            },
            {
              "operator": 'ALL',
              "_comment": 'HUD: Rural Special NOFO – Collection required for Permanent Supportive Housing',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HUD: Rural Special NOFO',
                },
                {
                  "variable": 'projectType',
                  "operator": 'EQUAL',
                  "value": 3,
                },
              ],
            },
          ],
        },
      },
      # r11_ward_of_child_welfare
      R11: {
        stages: [:INTAKE],
        data_collected_about: :HOH_AND_ADULTS,
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "operator": 'ALL',
              "_comment": 'HHS: RHY – Collection required for all components except for Street Outreach',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HHS: RHY',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 4,
                },
              ],
            },
            {
              "_comment": 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 43,
            },
          ],
        },
      },
      # r12_ward_of_juvenile_justice
      R12: {
        stages: [:INTAKE],
        data_collected_about: :HOH_AND_ADULTS,
        rule: {
          "operator": 'ANY',
          "parts": [
            {
              "operator": 'ALL',
              "_comment": 'HHS: RHY – Collection required for all components except for Street Outreach',
              "parts": [
                {
                  "variable": 'projectFunderComponents',
                  "operator": 'INCLUDE',
                  "value": 'HHS: RHY',
                },
                {
                  "variable": 'projectType',
                  "operator": 'NOT_EQUAL',
                  "value": 4,
                },
              ],
            },
            {
              "_comment": 'Included in YHDP Supplemental CSV. Recommended for YHDP projects.',
              "variable": 'projectFunders',
              "operator": 'INCLUDE',
              "value": 43,
            },
          ],
        },
      },
      # r13_family_critical_issues
      R13: {
        stages: [:INTAKE],
        data_collected_about: :HOH_AND_ADULTS,
        rule: {
          "operator": 'ALL',
          "_comment": 'HHS: RHY – Collection required for all components except for Street Outreach',
          "parts": [
            {
              "variable": 'projectFunderComponents',
              "operator": 'INCLUDE',
              "value": 'HHS: RHY',
            },
            {
              "variable": 'projectType',
              "operator": 'NOT_EQUAL',
              "value": 4,
            },
          ],
        },
      },
    }.freeze

    def role_to_link_ids
      @role_to_link_ids ||= HUD_LINK_ID_RULES.each_with_object({}) do |(link_id, config), hash|
        config[:stages].each do |role|
          hash[role] ||= []
          hash[role] << link_id
        end
      end
    end

    def hud_data_element?(form_role, link_id)
      HUD_LINK_ID_RULES.key?(link_id.to_sym) && HUD_LINK_ID_RULES[link_id.to_sym][:stages].include?(form_role.to_sym)
    end

    def hud_data_element_rule(form_role, link_id)
      return unless hud_data_element?(form_role.to_sym, link_id.to_sym)

      HUD_LINK_ID_RULES[link_id.to_sym][:rule]
    end

    def hud_data_element_data_collected_about(form_role, link_id)
      return unless hud_data_element?(form_role.to_sym, link_id.to_sym)

      HUD_LINK_ID_RULES[link_id.to_sym][:data_collected_about]
    end

    def required_link_ids_for_role(role)
      role_to_link_ids[role.to_sym] || []
    end
  end
end
