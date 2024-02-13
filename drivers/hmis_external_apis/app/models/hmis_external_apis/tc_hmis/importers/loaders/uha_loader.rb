###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class UhaLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # generated by UhaHeaderBuilder
    CDED_CONFIGS =
      [
        { element_id: nil, label: 'Program Name', key: 'uha_program_name', repeats: false, field_type: 'string' },
        { element_id: nil, label: 'Case Number', key: 'uha_case_number', repeats: false, field_type: 'string' },
        { element_id: nil, label: 'Unique Enrollment Identifier', key: 'uha_unique_enrollment_identifier', repeats: false, field_type: 'string' },
        { element_id: nil, label: 'Response ID', key: 'uha_response_id', repeats: false, field_type: 'string' },
        { element_id: nil, label: 'Date Taken', key: 'uha_date_taken', repeats: false, field_type: 'string' },
        { element_id: nil, label: 'Participant Enterprise Identifier', key: 'uha_participant_enterprise_identifier', repeats: false, field_type: 'string' },
        { element_id: 12275, label: 'Alternate Mailing Address', key: 'uha_alt_mail_country', repeats: false, field_type: 'string' },
        { element_id: 12276, label: 'Name', key: 'uha_alt_mail_name', repeats: false, field_type: 'string' },
        { element_id: 12277, label: 'Address Line 1', key: 'uha_alt_mail_address_line_1', repeats: false, field_type: 'string' },
        { element_id: 12278, label: 'Address Line 2', key: 'uha_alt_mail_address_line_2', repeats: false, field_type: 'string' },
        { element_id: 12279, label: 'City', key: 'uha_alt_mail_city', repeats: false, field_type: 'string' },
        { element_id: 12280, label: 'State', key: 'uha_alt_mail_state', repeats: false, field_type: 'string' },
        { element_id: 12281, label: 'County', key: 'uha_alt_mail_county', repeats: false, field_type: 'string' },
        { element_id: 12282, label: 'Zip Code', key: 'uha_alt_mail_zip_code', repeats: false, field_type: 'string' },
        { element_id: 12286,
          label: "Citizenship:\n\n Are you and all family members a U.S. Citizen or have eligible immigration status?",
          key: 'uha_key_12286',
          repeats: false,
          field_type: 'string' },
        { element_id: 12287,
          label: 'If you answered No, list the person(s) who are not eligible or a U.S. Citizen:',
          key: 'uha_key_12287',
          repeats: false,
          field_type: 'string' },
        { element_id: 12295, label: 'Name', key: 'uha_income_name_1', repeats: false, field_type: 'string' },
        { element_id: 12296, label: 'Name', key: 'uha_income_name_2', repeats: false, field_type: 'string' },
        { element_id: 12297, label: 'Name', key: 'uha_income_name_3', repeats: false, field_type: 'string' },
        { element_id: 12298, label: 'Name', key: 'uha_income_name_4', repeats: false, field_type: 'string' },
        { element_id: 12299, label: 'Name', key: 'uha_income_name_5', repeats: false, field_type: 'string' },
        { element_id: 12300, label: 'Source and Type', key: 'uha_income_source_and_type_1', repeats: false, field_type: 'string' },
        { element_id: 12301, label: 'Source and Type', key: 'uha_income_source_and_type_2', repeats: false, field_type: 'string' },
        { element_id: 12302, label: 'Source and Type', key: 'uha_income_source_and_type_3', repeats: false, field_type: 'string' },
        { element_id: 12303, label: 'Source and Type', key: 'uha_income_source_and_type_4', repeats: false, field_type: 'string' },
        { element_id: 12304, label: 'Source and Type', key: 'uha_income_source_and_type_5', repeats: false, field_type: 'string' },
        { element_id: 12305, label: 'Gross', key: 'uha_income_gross_1', repeats: false, field_type: 'string' },
        { element_id: 12306, label: 'Gross', key: 'uha_income_gross_2', repeats: false, field_type: 'string' },
        { element_id: 12307, label: 'Gross', key: 'uha_income_gross_3', repeats: false, field_type: 'string' },
        { element_id: 12308, label: 'Gross', key: 'uha_income_gross_4', repeats: false, field_type: 'string' },
        { element_id: 12309, label: 'Gross', key: 'uha_income_gross_5', repeats: false, field_type: 'string' },
        { element_id: 12313,
          label: 'Are you or any other adult family member in the household a Registered Lifetime Sex Offender?',
          key: 'uha_key_12313',
          repeats: false,
          field_type: 'string' },
        { element_id: 12315,
          label: 'Have you or any other family member in the household been found guilty of manufacturing or produced methamphetamine on the premises of federally assisted housing?',
          key: 'uha_key_12315',
          repeats: false,
          field_type: 'string' },
        { element_id: 12316,
          label: 'If you answered yes to either question in Criminal Background Section, please explain:',
          key: 'uha_key_12316',
          repeats: false,
          field_type: 'string' },
        { element_id: 12319, label: 'Date', key: 'uha_applicant_certification_head_of_household_signature_date', repeats: false, field_type: 'string' },
        { element_id: 12320, label: 'Signature', key: 'uha_applicant_certification_spouse_signature_1', repeats: false, field_type: 'string' },
        { element_id: 12321, label: 'Date', key: 'uha_applicant_certification_spouse_signature_date', repeats: false, field_type: 'string' },
        { element_id: 12324, label: 'Address 1', key: 'uha_hoh_address_1', repeats: false, field_type: 'string' },
        { element_id: 12325, label: 'Address 2', key: 'uha_hoh_address_2', repeats: false, field_type: 'string' },
        { element_id: 12326, label: 'ZipCode', key: 'uha_hoh_zipcode', repeats: false, field_type: 'string' },
        { element_id: 12327, label: 'First Name', key: 'uha_hoh_first_name', repeats: false, field_type: 'string' },
        { element_id: 12328, label: 'Middle Initial', key: 'uha_hoh_middle_initial', repeats: false, field_type: 'string' },
        { element_id: 12329, label: 'Last Name', key: 'uha_hoh_last_name', repeats: false, field_type: 'string' },
        { element_id: 12332, label: 'Client Phone Number', key: 'uha_hoh_client_phone_number', repeats: false, field_type: 'string' },
        { element_id: 12333, label: 'Client Email', key: 'uha_hoh_client_email', repeats: false, field_type: 'string' },
        { element_id: 12334, label: 'Race (HUD)', key: 'uha_hoh_race_hud', repeats: true, field_type: 'string' },
        { element_id: 12335, label: 'Ethnicity (HUD)', key: 'uha_hoh_ethnicity_hud', repeats: true, field_type: 'string' },
        { element_id: 12348, label: 'First Name', key: 'uha_household_member_first_name_1', repeats: false, field_type: 'string' },
        { element_id: 12349, label: 'First Name', key: 'uha_household_member_first_name_2', repeats: false, field_type: 'string' },
        { element_id: 12350, label: 'First Name', key: 'uha_household_member_first_name_3', repeats: false, field_type: 'string' },
        { element_id: 12351, label: 'First Name', key: 'uha_household_member_first_name_4', repeats: false, field_type: 'string' },
        { element_id: 12352, label: 'First Name', key: 'uha_household_member_first_name_5', repeats: false, field_type: 'string' },
        { element_id: 12353, label: 'First Name', key: 'uha_household_member_first_name_6', repeats: false, field_type: 'string' },
        { element_id: 12354, label: 'First Name', key: 'uha_household_member_first_name_7', repeats: false, field_type: 'string' },
        { element_id: 12355, label: 'First Name', key: 'uha_household_member_first_name_8', repeats: false, field_type: 'string' },
        { element_id: 12356, label: 'First Name', key: 'uha_household_member_first_name_9', repeats: false, field_type: 'string' },
        { element_id: 12357, label: 'First Name', key: 'uha_household_member_first_name_10', repeats: false, field_type: 'string' },
        { element_id: 12358, label: 'First Name', key: 'uha_household_member_first_name_11', repeats: false, field_type: 'string' },
        { element_id: 12359, label: 'Middle Initial', key: 'uha_household_member_middle_initial_1', repeats: false, field_type: 'string' },
        { element_id: 12360, label: 'Middle Initial', key: 'uha_household_member_middle_initial_2', repeats: false, field_type: 'string' },
        { element_id: 12361, label: 'Middle Initial', key: 'uha_household_member_middle_initial_3', repeats: false, field_type: 'string' },
        { element_id: 12362, label: 'Middle Initial', key: 'uha_household_member_middle_initial_4', repeats: false, field_type: 'string' },
        { element_id: 12363, label: 'Middle Initial', key: 'uha_household_member_middle_initial_5', repeats: false, field_type: 'string' },
        { element_id: 12364, label: 'Middle Initial', key: 'uha_household_member_middle_initial_6', repeats: false, field_type: 'string' },
        { element_id: 12365, label: 'Middle Initial', key: 'uha_household_member_middle_initial_7', repeats: false, field_type: 'string' },
        { element_id: 12366, label: 'Middle Initial', key: 'uha_household_member_middle_initial_8', repeats: false, field_type: 'string' },
        { element_id: 12367, label: 'Middle Initial', key: 'uha_household_member_middle_initial_9', repeats: false, field_type: 'string' },
        { element_id: 12368, label: 'Middle Initial', key: 'uha_household_member_middle_initial_10', repeats: false, field_type: 'string' },
        { element_id: 12369, label: 'Middle Initial', key: 'uha_household_member_middle_initial_11', repeats: false, field_type: 'string' },
        { element_id: 12370, label: 'Last Name', key: 'uha_household_member_last_name_1', repeats: false, field_type: 'string' },
        { element_id: 12371, label: 'Last Name', key: 'uha_household_member_last_name_2', repeats: false, field_type: 'string' },
        { element_id: 12372, label: 'Last Name', key: 'uha_household_member_last_name_3', repeats: false, field_type: 'string' },
        { element_id: 12373, label: 'Last Name', key: 'uha_household_member_last_name_4', repeats: false, field_type: 'string' },
        { element_id: 12374, label: 'Last Name', key: 'uha_household_member_last_name_5', repeats: false, field_type: 'string' },
        { element_id: 12375, label: 'Last Name', key: 'uha_household_member_last_name_6', repeats: false, field_type: 'string' },
        { element_id: 12376, label: 'Last Name', key: 'uha_household_member_last_name_7', repeats: false, field_type: 'string' },
        { element_id: 12377, label: 'Last Name', key: 'uha_household_member_last_name_8', repeats: false, field_type: 'string' },
        { element_id: 12378, label: 'Last Name', key: 'uha_household_member_last_name_9', repeats: false, field_type: 'string' },
        { element_id: 12379, label: 'Last Name', key: 'uha_household_member_last_name_10', repeats: false, field_type: 'string' },
        { element_id: 12380, label: 'Last Name', key: 'uha_household_member_last_name_11', repeats: false, field_type: 'string' },
        { element_id: 12392,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_1',
          repeats: false,
          field_type: 'string' },
        { element_id: 12393,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_2',
          repeats: false,
          field_type: 'string' },
        { element_id: 12394,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_3',
          repeats: false,
          field_type: 'string' },
        { element_id: 12395,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_4',
          repeats: false,
          field_type: 'string' },
        { element_id: 12396,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_5',
          repeats: false,
          field_type: 'string' },
        { element_id: 12397,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_6',
          repeats: false,
          field_type: 'string' },
        { element_id: 12398,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_7',
          repeats: false,
          field_type: 'string' },
        { element_id: 12399,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_8',
          repeats: false,
          field_type: 'string' },
        { element_id: 12400,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_9',
          repeats: false,
          field_type: 'string' },
        { element_id: 12401,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_10',
          repeats: false,
          field_type: 'string' },
        { element_id: 12402,
          label: 'Relationship to Head of Household',
          key: 'uha_household_member_relationship_to_head_of_household_11',
          repeats: false,
          field_type: 'string' },
        { element_id: 12414, label: 'Citizenship', key: 'uha_household_member_citizenship_1', repeats: false, field_type: 'string' },
        { element_id: 12415, label: 'Citizenship', key: 'uha_household_member_citizenship_2', repeats: false, field_type: 'string' },
        { element_id: 12416, label: 'Citizenship', key: 'uha_household_member_citizenship_3', repeats: false, field_type: 'string' },
        { element_id: 12417, label: 'Citizenship', key: 'uha_household_member_citizenship_4', repeats: false, field_type: 'string' },
        { element_id: 12418, label: 'Citizenship', key: 'uha_household_member_citizenship_5', repeats: false, field_type: 'string' },
        { element_id: 12419, label: 'Citizenship', key: 'uha_household_member_citizenship_6', repeats: false, field_type: 'string' },
        { element_id: 12420, label: 'Citizenship', key: 'uha_household_member_citizenship_7', repeats: false, field_type: 'string' },
        { element_id: 12421, label: 'Citizenship', key: 'uha_household_member_citizenship_8', repeats: false, field_type: 'string' },
        { element_id: 12422, label: 'Citizenship', key: 'uha_household_member_citizenship_9', repeats: false, field_type: 'string' },
        { element_id: 12423, label: 'Citizenship', key: 'uha_household_member_citizenship_10', repeats: false, field_type: 'string' },
        { element_id: 12424, label: 'Citizenship', key: 'uha_household_member_citizenship_11', repeats: false, field_type: 'string' },
        { element_id: 12425, label: 'Sex', key: 'uha_household_member_sex_1', repeats: false, field_type: 'string' },
        { element_id: 12426, label: 'Sex', key: 'uha_household_member_sex_2', repeats: false, field_type: 'string' },
        { element_id: 12427, label: 'Sex', key: 'uha_household_member_sex_3', repeats: false, field_type: 'string' },
        { element_id: 12428, label: 'Sex', key: 'uha_household_member_sex_4', repeats: false, field_type: 'string' },
        { element_id: 12429, label: 'Sex', key: 'uha_household_member_sex_5', repeats: false, field_type: 'string' },
        { element_id: 12430, label: 'Sex', key: 'uha_household_member_sex_6', repeats: false, field_type: 'string' },
        { element_id: 12431, label: 'Sex', key: 'uha_household_member_sex_7', repeats: false, field_type: 'string' },
        { element_id: 12432, label: 'Sex', key: 'uha_household_member_sex_8', repeats: false, field_type: 'string' },
        { element_id: 12433, label: 'Sex', key: 'uha_household_member_sex_9', repeats: false, field_type: 'string' },
        { element_id: 12434, label: 'Sex', key: 'uha_household_member_sex_10', repeats: false, field_type: 'string' },
        { element_id: 12435, label: 'Sex', key: 'uha_household_member_sex_11', repeats: false, field_type: 'string' },
        { element_id: 12436, label: 'Disabled', key: 'uha_household_member_disabled_1', repeats: false, field_type: 'string' },
        { element_id: 12437, label: 'Disabled', key: 'uha_household_member_disabled_2', repeats: false, field_type: 'string' },
        { element_id: 12438, label: 'Disabled', key: 'uha_household_member_disabled_3', repeats: false, field_type: 'string' },
        { element_id: 12439, label: 'Disabled', key: 'uha_household_member_disabled_4', repeats: false, field_type: 'string' },
        { element_id: 12440, label: 'Disabled', key: 'uha_household_member_disabled_5', repeats: false, field_type: 'string' },
        { element_id: 12441, label: 'Disabled', key: 'uha_household_member_disabled_6', repeats: false, field_type: 'string' },
        { element_id: 12442, label: 'Disabled', key: 'uha_household_member_disabled_7', repeats: false, field_type: 'string' },
        { element_id: 12443, label: 'Disabled', key: 'uha_household_member_disabled_8', repeats: false, field_type: 'string' },
        { element_id: 12444, label: 'Disabled', key: 'uha_household_member_disabled_9', repeats: false, field_type: 'string' },
        { element_id: 12445, label: 'Disabled', key: 'uha_household_member_disabled_10', repeats: false, field_type: 'string' },
        { element_id: 12446, label: 'Disabled', key: 'uha_household_member_disabled_11', repeats: false, field_type: 'string' },
        { element_id: 12447, label: 'Race', key: 'uha_household_member_race_1', repeats: false, field_type: 'string' },
        { element_id: 12448, label: 'Race', key: 'uha_household_member_race_2', repeats: false, field_type: 'string' },
        { element_id: 12449, label: 'Race', key: 'uha_household_member_race_3', repeats: false, field_type: 'string' },
        { element_id: 12450, label: 'Race', key: 'uha_household_member_race_4', repeats: false, field_type: 'string' },
        { element_id: 12451, label: 'Race', key: 'uha_household_member_race_5', repeats: false, field_type: 'string' },
        { element_id: 12452, label: 'Race', key: 'uha_household_member_race_6', repeats: false, field_type: 'string' },
        { element_id: 12453, label: 'Race', key: 'uha_household_member_race_7', repeats: false, field_type: 'string' },
        { element_id: 12454, label: 'Race', key: 'uha_household_member_race_8', repeats: false, field_type: 'string' },
        { element_id: 12455, label: 'Race', key: 'uha_household_member_race_9', repeats: false, field_type: 'string' },
        { element_id: 12456, label: 'Race', key: 'uha_household_member_race_10', repeats: false, field_type: 'string' },
        { element_id: 12457, label: 'Race', key: 'uha_household_member_race_11', repeats: false, field_type: 'string' },
        { element_id: 12459, label: 'Date', key: 'uha_applicant_certification_tx_601_rep_signature_date', repeats: false, field_type: 'string' },
        { element_id: 12561,
          label: 'Head of Household Signature:',
          key: 'uha_applicant_certification_head_of_household_signature_1',
          repeats: false,
          field_type: 'string' },
        { element_id: 12564, label: 'Gender (HUD)', key: 'uha_hoh_gender_hud', repeats: true, field_type: 'string' },
        { element_id: 12572, label: 'Name', key: 'uha_asset_info_name_1', repeats: false, field_type: 'string' },
        { element_id: 12573, label: 'Source and Type', key: 'uha_asset_info_source_and_type_1', repeats: false, field_type: 'string' },
        { element_id: 12574, label: 'Gross', key: 'uha_asset_info_gross_1', repeats: false, field_type: 'string' },
        { element_id: 12575, label: 'Name', key: 'uha_asset_info_name_2', repeats: false, field_type: 'string' },
        { element_id: 12576, label: 'Source and Type', key: 'uha_asset_info_source_and_type_2', repeats: false, field_type: 'string' },
        { element_id: 12577, label: 'Gross', key: 'uha_asset_info_gross_2', repeats: false, field_type: 'string' },
        { element_id: 12578, label: 'Name', key: 'uha_asset_info_name_3', repeats: false, field_type: 'string' },
        { element_id: 12579, label: 'Source and Type', key: 'uha_asset_info_source_and_type_3', repeats: false, field_type: 'string' },
        { element_id: 12580, label: 'Gross', key: 'uha_asset_info_gross_3', repeats: false, field_type: 'string' },
        { element_id: 12581, label: 'Name', key: 'uha_asset_info_name_4', repeats: false, field_type: 'string' },
        { element_id: 12582, label: 'Source and Type', key: 'uha_asset_info_source_and_type_4', repeats: false, field_type: 'string' },
        { element_id: 12583, label: 'Gross', key: 'uha_asset_info_gross_4', repeats: false, field_type: 'string' },
        { element_id: 12584, label: 'Name', key: 'uha_asset_info_name_5', repeats: false, field_type: 'string' },
        { element_id: 12585, label: 'Source and Type', key: 'uha_asset_info_source_and_type_5', repeats: false, field_type: 'string' },
        { element_id: 12586, label: 'Gross', key: 'uha_asset_info_gross_5', repeats: false, field_type: 'string' },
        { element_id: 12692, label: 'Name', key: 'uha_household_contrib_name_1', repeats: false, field_type: 'string' },
        { element_id: 12693, label: 'Source and Type', key: 'uha_household_contrib_source_and_type_1', repeats: false, field_type: 'string' },
        { element_id: 12694, label: 'Gross', key: 'uha_household_contrib_gross_1', repeats: false, field_type: 'string' },
        { element_id: 12695, label: 'Name', key: 'uha_household_contrib_name_2', repeats: false, field_type: 'string' },
        { element_id: 12696, label: 'Source and Type', key: 'uha_household_contrib_source_and_type_2', repeats: false, field_type: 'string' },
        { element_id: 12697, label: 'Gross', key: 'uha_household_contrib_gross_2', repeats: false, field_type: 'string' },
        { element_id: 12698, label: 'Name', key: 'uha_household_contrib_name_3', repeats: false, field_type: 'string' },
        { element_id: 12699, label: 'Source and Type', key: 'uha_household_contrib_source_and_type_3', repeats: false, field_type: 'string' },
        { element_id: 12700, label: 'Gross', key: 'uha_household_contrib_gross_3', repeats: false, field_type: 'string' },
        { element_id: 12701, label: 'Name', key: 'uha_household_contrib_name_4', repeats: false, field_type: 'string' },
        { element_id: 12702, label: 'Source and Type', key: 'uha_household_contrib_source_and_type_4', repeats: false, field_type: 'string' },
        { element_id: 12703, label: 'Gross', key: 'uha_household_contrib_gross_4', repeats: false, field_type: 'string' },
        { element_id: 12704, label: 'Name', key: 'uha_household_contrib_name_5', repeats: false, field_type: 'string' },
        { element_id: 12705, label: 'Source and Type', key: 'uha_household_contrib_source_and_type_5', repeats: false, field_type: 'string' },
        { element_id: 12706, label: 'Gross', key: 'uha_household_contrib_gross_5', repeats: false, field_type: 'string' },
        { element_id: 12715, label: 'first name', key: 'uha_meth_manufacture_first_name_1', repeats: false, field_type: 'string' },
        { element_id: 12716, label: 'first name', key: 'uha_meth_manufacture_first_name_2', repeats: false, field_type: 'string' },
        { element_id: 12717, label: 'first name', key: 'uha_meth_manufacture_first_name_3', repeats: false, field_type: 'string' },
        { element_id: 12718, label: 'last name', key: 'uha_meth_manufacture_last_name_1', repeats: false, field_type: 'string' },
        { element_id: 12719, label: 'last name', key: 'uha_meth_manufacture_last_name_2', repeats: false, field_type: 'string' },
        { element_id: 12720, label: 'last name', key: 'uha_meth_manufacture_last_name_3', repeats: false, field_type: 'string' },
        { element_id: 12721, label: 'date of birth', key: 'uha_meth_manufacture_date_of_birth_1', repeats: false, field_type: 'string' },
        { element_id: 12722, label: 'date of birth', key: 'uha_meth_manufacture_date_of_birth_2', repeats: false, field_type: 'string' },
        { element_id: 12723, label: 'date of birth', key: 'uha_meth_manufacture_date_of_birth_3', repeats: false, field_type: 'string' },
        { element_id: 12728, label: 'first name', key: 'uha_sex_offender_first_name_1', repeats: false, field_type: 'string' },
        { element_id: 12729, label: 'last name', key: 'uha_sex_offender_last_name_1', repeats: false, field_type: 'string' },
        { element_id: 12730, label: 'date of birth', key: 'uha_sex_offender_date_of_birth_1', repeats: false, field_type: 'string' },
        { element_id: 12731, label: 'first name', key: 'uha_sex_offender_first_name_2', repeats: false, field_type: 'string' },
        { element_id: 12732, label: 'last name', key: 'uha_sex_offender_last_name_2', repeats: false, field_type: 'string' },
        { element_id: 12733, label: 'date of birth', key: 'uha_sex_offender_date_of_birth_2', repeats: false, field_type: 'string' },
        { element_id: 12734, label: 'first name', key: 'uha_sex_offender_first_name_3', repeats: false, field_type: 'string' },
        { element_id: 12735, label: 'last name', key: 'uha_sex_offender_last_name_3', repeats: false, field_type: 'string' },
        { element_id: 12736, label: 'date of birth', key: 'uha_sex_offender_date_of_birth_3', repeats: false, field_type: 'string' },
        { element_id: 12739,
          label: 'Other Adult Household Member Signature',
          key: 'uha_applicant_certification_other_adult_household_member_signature_1',
          repeats: false,
          field_type: 'string' },
        { element_id: 12740,
          label: 'Date:',
          key: 'uha_applicant_certification_other_adult_household_member_signature_date_1',
          repeats: false,
          field_type: 'string' },
        { element_id: 12741,
          label: 'Other Adult Household Member Signature',
          key: 'uha_applicant_certification_other_adult_household_member_signature_2',
          repeats: false,
          field_type: 'string' },
        { element_id: 12742,
          label: 'Date:',
          key: 'uha_applicant_certification_other_adult_household_member_signature_date_2',
          repeats: false,
          field_type: 'string' },
        { element_id: 12745, label: 'Agency Name:', key: 'uha_agency_name', repeats: false, field_type: 'string' },
        { element_id: 12746, label: 'Program/Project Name:', key: 'uha_program_project_name', repeats: false, field_type: 'string' },
        { element_id: 12748, label: 'Signature', key: 'uha_applicant_certification_tx_601_rep_signature', repeats: false, field_type: 'string' },
        { element_id: 12891, label: 'Signature', key: 'uha_consent_for_roi_hoh_signature', repeats: false, field_type: 'string' },
        { element_id: 12892, label: 'Date:', key: 'uha_consent_for_roi_hoh_signature_date', repeats: false, field_type: 'string' },
        { element_id: 12893, label: 'Signature', key: 'uha_consent_for_roi_spouse_signature', repeats: false, field_type: 'string' },
        { element_id: 12894, label: 'Date:', key: 'uha_consent_for_roi_spouse_signature_date', repeats: false, field_type: 'string' },
        { element_id: 12895, label: 'Signature', key: 'uha_consent_for_roi_additional_household_member_signature', repeats: false, field_type: 'string' },
        { element_id: 12896, label: 'Date:', key: 'uha_consent_for_roi_additional_household_member_signature_date', repeats: false, field_type: 'string' },
        { element_id: 13028, label: 'Expense', key: 'uha_medical_expense_1', repeats: false, field_type: 'string' },
        { element_id: 13029, label: 'Expense', key: 'uha_medical_expense_2', repeats: false, field_type: 'string' },
        { element_id: 13030, label: 'Expense', key: 'uha_medical_expense_3', repeats: false, field_type: 'string' },
        { element_id: 13031, label: 'Expense', key: 'uha_medical_expense_4', repeats: false, field_type: 'string' },
        { element_id: 13032, label: 'Expense', key: 'uha_medical_expense_5', repeats: false, field_type: 'string' },
        { element_id: 13033, label: 'Expense', key: 'uha_medical_expense_6', repeats: false, field_type: 'string' },
        { element_id: 13034, label: 'Amount', key: 'uha_medical_expense_amount_1', repeats: false, field_type: 'string' },
        { element_id: 13035, label: 'Amount', key: 'uha_medical_expense_amount_2', repeats: false, field_type: 'string' },
        { element_id: 13036, label: 'Amount', key: 'uha_medical_expense_amount_3', repeats: false, field_type: 'string' },
        { element_id: 13037, label: 'Amount', key: 'uha_medical_expense_amount_4', repeats: false, field_type: 'string' },
        { element_id: 13038, label: 'Amount', key: 'uha_medical_expense_amount_5', repeats: false, field_type: 'string' },
        { element_id: 13039, label: 'Amount', key: 'uha_medical_expense_amount_6', repeats: false, field_type: 'string' },
        { element_id: 13048, label: 'Name', key: 'uha_childcare_name_1', repeats: false, field_type: 'string' },
        { element_id: 13049, label: 'Name', key: 'uha_childcare_name_2', repeats: false, field_type: 'string' },
        { element_id: 13050, label: 'Name', key: 'uha_childcare_name_3', repeats: false, field_type: 'string' },
        { element_id: 13051, label: 'Name', key: 'uha_childcare_name_4', repeats: false, field_type: 'string' },
        { element_id: 13052, label: 'Name', key: 'uha_childcare_name_5', repeats: false, field_type: 'string' },
        { element_id: 13053, label: 'Name', key: 'uha_childcare_name_6', repeats: false, field_type: 'string' },
        { element_id: 13054, label: 'Contact', key: 'uha_childcare_contact_1', repeats: false, field_type: 'string' },
        { element_id: 13055, label: 'Contact', key: 'uha_childcare_contact_2', repeats: false, field_type: 'string' },
        { element_id: 13056, label: 'Contact', key: 'uha_childcare_contact_3', repeats: false, field_type: 'string' },
        { element_id: 13057, label: 'Contact', key: 'uha_childcare_contact_4', repeats: false, field_type: 'string' },
        { element_id: 13058, label: 'Contact', key: 'uha_childcare_contact_5', repeats: false, field_type: 'string' },
        { element_id: 13059, label: 'Contact', key: 'uha_childcare_contact_6', repeats: false, field_type: 'string' },
        { element_id: 13084, label: 'Date', key: 'uha_cch_client_signature_date', repeats: false, field_type: 'string' },
        { element_id: 13086, label: 'CCH Report Printed?', key: 'uha_cch_purpose', repeats: false, field_type: 'string' },
        { element_id: 13088, label: 'Purpose of CCH', key: 'uha_cch_purpose_of_cch', repeats: false, field_type: 'string' },
        { element_id: 13089, label: 'Hired?', key: 'uha_cch_hired', repeats: false, field_type: 'string' },
        { element_id: 13091, label: 'Date Printed', key: 'uha_cch_date_printed', repeats: false, field_type: 'string' },
        { element_id: 13092, label: 'Destroyed Date', key: 'uha_cch_destroyed_date', repeats: false, field_type: 'string' },
        { element_id: 13095, label: 'New Admission or Existing Client?', key: 'uha_cch_new_admission_or_existing_client', repeats: false, field_type: 'string' },
        { element_id: 13097, label: 'Date of Birth', key: 'uha_cch_date_of_birth', repeats: false, field_type: 'string' },
        { element_id: 13098,
          label: 'For out of state searches - list cities, counties, and states below:',
          key: 'uha_cch_key_13098',
          field_type: 'string' },
        { element_id: 13099, label: 'RESULTS', key: 'uha_cch_results', repeats: false, field_type: 'string' },
        { element_id: 13101, label: 'Requestor Name', key: 'uha_cch_requestor_name', repeats: false, field_type: 'string' },
        { element_id: 13102, label: 'Request Date', key: 'uha_cch_request_date', repeats: false, field_type: 'string' },
        { element_id: 13104, label: 'Screening Conducted By', key: 'uha_cch_screening_conducted_by', repeats: false, field_type: 'string' },
        { element_id: 13105, label: 'Completion Date', key: 'uha_cch_completion_date', repeats: false, field_type: 'string' },
        { element_id: 13119, label: 'Client Signature:', key: 'uha_cch_client_signature', repeats: false, field_type: 'string' },
        { element_id: 13120, label: 'Initial of Staff:', key: 'uha_cch_initial_of_staff_1', repeats: false, field_type: 'string' },
        { element_id: 13121, label: 'Initial of Staff:', key: 'uha_cch_initial_of_staff_2', repeats: false, field_type: 'string' },
        { element_id: 13122, label: 'Program Name', key: 'uha_cch_program_name_1', repeats: false, field_type: 'string' },
        { element_id: 13123, label: 'Agency Representative:', key: 'uha_cch_agency_representative', repeats: false, field_type: 'string' },
        { element_id: 13124, label: 'Staff Signature:', key: 'uha_cch_staff_signature', repeats: false, field_type: 'string' },
        { element_id: 13125, label: 'Date:', key: 'uha_cch_date', repeats: false, field_type: 'string' },
        { element_id: 13126, label: 'Date', key: 'uha_cch_staff_signature_date', repeats: false, field_type: 'string' },
        { element_id: 13129, label: 'Participant Name', key: 'uha_cch_participant_name', repeats: false, field_type: 'string' },
        { element_id: 13131, label: 'Program Name', key: 'uha_cch_program_name_2', repeats: false, field_type: 'string' },
        { element_id: 13134, label: 'Head of Household Name:', key: 'uha_cch_head_of_household_name', repeats: false, field_type: 'string' },
        { element_id: 13135, label: 'Participant', key: 'uha_cch_participant', repeats: false, field_type: 'string' },
      ].freeze

    def filename
      'UHA.xlsx'
    end

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      row.field_value(ASSESSMENT_DATE_COL)
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "uha-eto-#{response_id}"
    end

    def cde_values(row, config)
      label = config.fetch(:label)
      values = super(row, config)
      values = values.map { |value| value ? 'Signed in ETO' : nil } if label =~ /signature/i
      values
    end
  end
end