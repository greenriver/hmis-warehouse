###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOT USED: this import was not necessary. Code left for reference

module HmisExternalApis::TcHmis::Importers::Loaders
  class EhvApplicationLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_CONFIGS = [
      { element_id: 11094, label: 'Alternate Mailing Address', key: 'ehv_app_alt_mail_country', repeats: false, field_type: 'string' },
      { element_id: 11095, label: 'Name', key: 'ehv_app_alt_mail_alt_mail_name', repeats: false, field_type: 'string' },
      { element_id: 11096, label: 'Address Line 1', key: 'ehv_app_alt_mail_address_line_1', repeats: false, field_type: 'string' },
      { element_id: 11097, label: 'Address Line 2', key: 'ehv_app_alt_mail_address_line_2', repeats: false, field_type: 'string' },
      { element_id: 11098, label: 'City', key: 'ehv_app_alt_mail_city', repeats: false, field_type: 'string' },
      { element_id: 11099, label: 'State', key: 'ehv_app_alt_mail_state', repeats: false, field_type: 'string' },
      { element_id: 11100, label: 'County', key: 'ehv_app_alt_mail_county', repeats: false, field_type: 'string' },
      { element_id: 11101, label: 'Zip Code', key: 'ehv_app_alt_mail_zip_code', repeats: false, field_type: 'string' },
      { element_id: 11105, label: 'Alternate Phone Number', key: 'ehv_app_alternate_phone_number', repeats: false, field_type: 'string' },
      { element_id: 11107, label: 'Disabled:', key: 'ehv_app_disabled', repeats: false, field_type: 'string' },
      { element_id: 11108, label: 'Marital Satus:', key: 'ehv_app_marital_satus', repeats: false, field_type: 'string' },
      { element_id: 11112,
        label: "Citizenship:\n\n Are you and all family members a U.S. Citizen or have eligible immigration status?",
        key: 'ehv_app_key_11112',
        repeats: false,
        field_type: 'string' },
      { element_id: 11113,
        label: 'If you answered No, list the person(s) who are not eligible or a U.S. Citizen:',
        key: 'ehv_app_key_11113',
        repeats: false,
        field_type: 'string' },
      { element_id: 11121, label: 'Name', key: 'ehv_app_income_name_1', repeats: false, field_type: 'string' },
      { element_id: 11122, label: 'Name', key: 'ehv_app_income_name_2', repeats: false, field_type: 'string' },
      { element_id: 11123, label: 'Name', key: 'ehv_app_income_name_3', repeats: false, field_type: 'string' },
      { element_id: 11124, label: 'Name', key: 'ehv_app_income_name_4', repeats: false, field_type: 'string' },
      { element_id: 11125, label: 'Name', key: 'ehv_app_income_name_5', repeats: false, field_type: 'string' },
      { element_id: 11126, label: 'Source and Type', key: 'ehv_app_income_source_and_type_1', repeats: false, field_type: 'string' },
      { element_id: 11127, label: 'Source and Type', key: 'ehv_app_income_source_and_type_2', repeats: false, field_type: 'string' },
      { element_id: 11128, label: 'Source and Type', key: 'ehv_app_income_source_and_type_3', repeats: false, field_type: 'string' },
      { element_id: 11129, label: 'Source and Type', key: 'ehv_app_income_source_and_type_4', repeats: false, field_type: 'string' },
      { element_id: 11130, label: 'Source and Type', key: 'ehv_app_income_source_and_type_5', repeats: false, field_type: 'string' },
      { element_id: 11131, label: 'Gross', key: 'ehv_app_income_gross_1', repeats: false, field_type: 'string' },
      { element_id: 11132, label: 'Gross', key: 'ehv_app_income_gross_2', repeats: false, field_type: 'string' },
      { element_id: 11133, label: 'Gross', key: 'ehv_app_income_gross_3', repeats: false, field_type: 'string' },
      { element_id: 11134, label: 'Gross', key: 'ehv_app_income_gross_4', repeats: false, field_type: 'string' },
      { element_id: 11135, label: 'Gross', key: 'ehv_app_income_gross_5', repeats: false, field_type: 'string' },
      { element_id: 11184,
        label: 'Are you or any other adult family member in the household a Registered Lifetime Sex Offender?',
        key: 'ehv_app_key_11184',
        repeats: false,
        field_type: 'string' },
      { element_id: 11185,
        label: 'If Yes, please list the family member name',
        key: 'ehv_app_if_yes_please_list_the_family_member_name',
        repeats: false,
        field_type: 'string' },
      { element_id: 11186,
        label: 'Have you or any other adult family member in the household been terminated because of meth amphetamines?',
        key: 'ehv_app_key_11186',
        repeats: false,
        field_type: 'string' },
      { element_id: 11187, label: 'If yes, please explain:', key: 'ehv_app_if_yes_please_explain', repeats: false, field_type: 'string' },
      { element_id: 11190, label: 'Date', key: 'ehv_app_app_cert_head_of_household_signature_date', repeats: false, field_type: 'string' },
      { element_id: 11191, label: 'Signature', key: 'ehv_app_app_cert_spouse_or_co_head_of_household_signature', repeats: false, field_type: 'string' },
      { element_id: 11192, label: 'Date', key: 'ehv_app_app_cert_spouse_or_co_head_of_household_signature_date', repeats: false, field_type: 'string' },
      { element_id: 11195, label: 'Address 1', key: 'ehv_app_address_1', repeats: false, field_type: 'string' },
      { element_id: 11196, label: 'Address 2', key: 'ehv_app_address_2', repeats: false, field_type: 'string' },
      { element_id: 11198, label: 'First Name', key: 'ehv_app_first_name', repeats: false, field_type: 'string' },
      { element_id: 11199, label: 'Middle Initial', key: 'ehv_app_middle_initial', repeats: false, field_type: 'string' },
      { element_id: 11200, label: 'Last Name', key: 'ehv_app_last_name', repeats: false, field_type: 'string' },
      { element_id: 11352, label: 'Client Phone Number', key: 'ehv_app_client_phone_number', repeats: false, field_type: 'string' },
      { element_id: 11354, label: 'Client Email', key: 'ehv_app_client_email', repeats: false, field_type: 'string' },
      { element_id: 11355, label: 'Race (HUD)', key: 'ehv_app_race_hud', repeats: true, field_type: 'string' },
      { element_id: 11356, label: 'Ethnicity (HUD)', key: 'ehv_app_ethnicity_hud', repeats: true, field_type: 'string' },
      { element_id: 11371, label: 'First Name', key: 'ehv_app_household_info_first_name_1', repeats: false, field_type: 'string' },
      { element_id: 11372, label: 'First Name', key: 'ehv_app_household_info_first_name_2', repeats: false, field_type: 'string' },
      { element_id: 11373, label: 'First Name', key: 'ehv_app_household_info_first_name_3', repeats: false, field_type: 'string' },
      { element_id: 11374, label: 'First Name', key: 'ehv_app_household_info_first_name_4', repeats: false, field_type: 'string' },
      { element_id: 11375, label: 'First Name', key: 'ehv_app_household_info_first_name_5', repeats: false, field_type: 'string' },
      { element_id: 11376, label: 'First Name', key: 'ehv_app_household_info_first_name_6', repeats: false, field_type: 'string' },
      { element_id: 11377, label: 'First Name', key: 'ehv_app_household_info_first_name_7', repeats: false, field_type: 'string' },
      { element_id: 11378, label: 'First Name', key: 'ehv_app_household_info_first_name_8', repeats: false, field_type: 'string' },
      { element_id: 11379, label: 'First Name', key: 'ehv_app_household_info_first_name_9', repeats: false, field_type: 'string' },
      { element_id: 11380, label: 'First Name', key: 'ehv_app_household_info_first_name_10', repeats: false, field_type: 'string' },
      { element_id: 11381, label: 'First Name', key: 'ehv_app_household_info_first_name_11', repeats: false, field_type: 'string' },
      { element_id: 11382, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_1', repeats: false, field_type: 'string' },
      { element_id: 11383, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_2', repeats: false, field_type: 'string' },
      { element_id: 11384, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_3', repeats: false, field_type: 'string' },
      { element_id: 11385, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_4', repeats: false, field_type: 'string' },
      { element_id: 11386, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_5', repeats: false, field_type: 'string' },
      { element_id: 11387, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_6', repeats: false, field_type: 'string' },
      { element_id: 11388, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_7', repeats: false, field_type: 'string' },
      { element_id: 11389, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_8', repeats: false, field_type: 'string' },
      { element_id: 11390, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_9', repeats: false, field_type: 'string' },
      { element_id: 11391, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_10', repeats: false, field_type: 'string' },
      { element_id: 11392, label: 'Middle Initial', key: 'ehv_app_household_info_middle_initial_11', repeats: false, field_type: 'string' },
      { element_id: 11393, label: 'Last Name', key: 'ehv_app_household_info_last_name_1', repeats: false, field_type: 'string' },
      { element_id: 11394, label: 'Last Name', key: 'ehv_app_household_info_last_name_2', repeats: false, field_type: 'string' },
      { element_id: 11395, label: 'Last Name', key: 'ehv_app_household_info_last_name_3', repeats: false, field_type: 'string' },
      { element_id: 11396, label: 'Last Name', key: 'ehv_app_household_info_last_name_4', repeats: false, field_type: 'string' },
      { element_id: 11397, label: 'Last Name', key: 'ehv_app_household_info_last_name_5', repeats: false, field_type: 'string' },
      { element_id: 11398, label: 'Last Name', key: 'ehv_app_household_info_last_name_6', repeats: false, field_type: 'string' },
      { element_id: 11399, label: 'Last Name', key: 'ehv_app_household_info_last_name_7', repeats: false, field_type: 'string' },
      { element_id: 11400, label: 'Last Name', key: 'ehv_app_household_info_last_name_8', repeats: false, field_type: 'string' },
      { element_id: 11401, label: 'Last Name', key: 'ehv_app_household_info_last_name_9', repeats: false, field_type: 'string' },
      { element_id: 11402, label: 'Last Name', key: 'ehv_app_household_info_last_name_10', repeats: false, field_type: 'string' },
      { element_id: 11403, label: 'Last Name', key: 'ehv_app_household_info_last_name_11', repeats: false, field_type: 'string' },
      { element_id: 11415,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_1',
        repeats: false,
        field_type: 'string' },
      { element_id: 11416,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_2',
        repeats: false,
        field_type: 'string' },
      { element_id: 11417,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_3',
        repeats: false,
        field_type: 'string' },
      { element_id: 11418,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_4',
        repeats: false,
        field_type: 'string' },
      { element_id: 11419,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_5',
        repeats: false,
        field_type: 'string' },
      { element_id: 11420,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_6',
        repeats: false,
        field_type: 'string' },
      { element_id: 11421,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_7',
        repeats: false,
        field_type: 'string' },
      { element_id: 11422,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_8',
        repeats: false,
        field_type: 'string' },
      { element_id: 11423,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_9',
        repeats: false,
        field_type: 'string' },
      { element_id: 11424,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_10',
        repeats: false,
        field_type: 'string' },
      { element_id: 11425,
        label: 'Relationship to Head of Household',
        key: 'ehv_app_household_info_relationship_to_head_of_household_11',
        repeats: false,
        field_type: 'string' },
      { element_id: 11437, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_1', repeats: false, field_type: 'string' },
      { element_id: 11438, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_2', repeats: false, field_type: 'string' },
      { element_id: 11439, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_3', repeats: false, field_type: 'string' },
      { element_id: 11440, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_4', repeats: false, field_type: 'string' },
      { element_id: 11441, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_5', repeats: false, field_type: 'string' },
      { element_id: 11442, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_6', repeats: false, field_type: 'string' },
      { element_id: 11443, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_7', repeats: false, field_type: 'string' },
      { element_id: 11444, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_8', repeats: false, field_type: 'string' },
      { element_id: 11445, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_9', repeats: false, field_type: 'string' },
      { element_id: 11446, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_10', repeats: false, field_type: 'string' },
      { element_id: 11447, label: 'Citizenship', key: 'ehv_app_household_info_citizenship_11', repeats: false, field_type: 'string' },
      { element_id: 11448, label: 'Sex', key: 'ehv_app_household_info_sex_1', repeats: false, field_type: 'string' },
      { element_id: 11449, label: 'Sex', key: 'ehv_app_household_info_sex_2', repeats: false, field_type: 'string' },
      { element_id: 11450, label: 'Sex', key: 'ehv_app_household_info_sex_3', repeats: false, field_type: 'string' },
      { element_id: 11451, label: 'Sex', key: 'ehv_app_household_info_sex_4', repeats: false, field_type: 'string' },
      { element_id: 11452, label: 'Sex', key: 'ehv_app_household_info_sex_5', repeats: false, field_type: 'string' },
      { element_id: 11453, label: 'Sex', key: 'ehv_app_household_info_sex_6', repeats: false, field_type: 'string' },
      { element_id: 11454, label: 'Sex', key: 'ehv_app_household_info_sex_7', repeats: false, field_type: 'string' },
      { element_id: 11455, label: 'Sex', key: 'ehv_app_household_info_sex_8', repeats: false, field_type: 'string' },
      { element_id: 11456, label: 'Sex', key: 'ehv_app_household_info_sex_9', repeats: false, field_type: 'string' },
      { element_id: 11457, label: 'Sex', key: 'ehv_app_household_info_sex_10', repeats: false, field_type: 'string' },
      { element_id: 11458, label: 'Sex', key: 'ehv_app_household_info_sex_11', repeats: false, field_type: 'string' },
      { element_id: 11459, label: 'Disabled', key: 'ehv_app_household_info_disabled_1', repeats: false, field_type: 'string' },
      { element_id: 11460, label: 'Disabled', key: 'ehv_app_household_info_disabled_2', repeats: false, field_type: 'string' },
      { element_id: 11461, label: 'Disabled', key: 'ehv_app_household_info_disabled_3', repeats: false, field_type: 'string' },
      { element_id: 11462, label: 'Disabled', key: 'ehv_app_household_info_disabled_4', repeats: false, field_type: 'string' },
      { element_id: 11463, label: 'Disabled', key: 'ehv_app_household_info_disabled_5', repeats: false, field_type: 'string' },
      { element_id: 11464, label: 'Disabled', key: 'ehv_app_household_info_disabled_6', repeats: false, field_type: 'string' },
      { element_id: 11465, label: 'Disabled', key: 'ehv_app_household_info_disabled_7', repeats: false, field_type: 'string' },
      { element_id: 11466, label: 'Disabled', key: 'ehv_app_household_info_disabled_8', repeats: false, field_type: 'string' },
      { element_id: 11467, label: 'Disabled', key: 'ehv_app_household_info_disabled_9', repeats: false, field_type: 'string' },
      { element_id: 11468, label: 'Disabled', key: 'ehv_app_household_info_disabled_10', repeats: false, field_type: 'string' },
      { element_id: 11469, label: 'Disabled', key: 'ehv_app_household_info_disabled_11', repeats: false, field_type: 'string' },
      { element_id: 11470, label: 'Race', key: 'ehv_app_household_info_race_1', repeats: false, field_type: 'string' },
      { element_id: 11471, label: 'Race', key: 'ehv_app_household_info_race_2', repeats: false, field_type: 'string' },
      { element_id: 11472, label: 'Race', key: 'ehv_app_household_info_race_3', repeats: false, field_type: 'string' },
      { element_id: 11473, label: 'Race', key: 'ehv_app_household_info_race_4', repeats: false, field_type: 'string' },
      { element_id: 11474, label: 'Race', key: 'ehv_app_household_info_race_5', repeats: false, field_type: 'string' },
      { element_id: 11475, label: 'Race', key: 'ehv_app_household_info_race_6', repeats: false, field_type: 'string' },
      { element_id: 11476, label: 'Race', key: 'ehv_app_household_info_race_7', repeats: false, field_type: 'string' },
      { element_id: 11477, label: 'Race', key: 'ehv_app_household_info_race_8', repeats: false, field_type: 'string' },
      { element_id: 11478, label: 'Race', key: 'ehv_app_household_info_race_9', repeats: false, field_type: 'string' },
      { element_id: 11479, label: 'Race', key: 'ehv_app_household_info_race_10', repeats: false, field_type: 'string' },
      { element_id: 11480, label: 'Race', key: 'ehv_app_household_info_race_11', repeats: false, field_type: 'string' },
      { element_id: 11484, label: '.', key: 'ehv_app_app_cert_signature', repeats: false, field_type: 'string' },
      { element_id: 11486, label: 'Date', key: 'ehv_app_app_cert_signature_date', repeats: false, field_type: 'string' },
      { element_id: 11666, label: 'sig', key: 'ehv_app_release_of_info_sig_3', repeats: false, field_type: 'string' },
      { element_id: 11668, label: 'signature', key: 'ehv_app_release_of_info_signature_2', repeats: false, field_type: 'string' },
      { element_id: 11669, label: 'date', key: 'ehv_app_release_of_info_date_1', repeats: false, field_type: 'string' },
      { element_id: 11671, label: 'date', key: 'ehv_app_release_of_info_date_2', repeats: false, field_type: 'string' },
      { element_id: 11672, label: 'date', key: 'ehv_app_release_of_info_date_3', repeats: false, field_type: 'string' },
      { element_id: 11673, label: 'sig', key: 'ehv_app_release_of_info_sig_4', repeats: false, field_type: 'string' },
      { element_id: 11674, label: 'date', key: 'ehv_app_release_of_info_date_4', repeats: false, field_type: 'string' },
      { element_id: 11675, label: 'sig', key: 'ehv_app_release_of_info_sig_5', repeats: false, field_type: 'string' },
      { element_id: 11676, label: 'date', key: 'ehv_app_release_of_info_date_5', repeats: false, field_type: 'string' },
      { element_id: 11681, label: 'signature', key: 'ehv_app_hud_release_signature', repeats: false, field_type: 'string' },
      { element_id: 11682, label: 'sig', key: 'ehv_app_hud_release_sig', repeats: false, field_type: 'string' },
      { element_id: 11683, label: 'date', key: 'ehv_app_hud_release_date_bb-28', repeats: false, field_type: 'string' },
      { element_id: 11685, label: 'date', key: 'ehv_app_hud_release_date_2', repeats: false, field_type: 'string' },
      { element_id: 11686, label: 'sig', key: 'ehv_app_hud_release_sig_2', repeats: false, field_type: 'string' },
      { element_id: 11687, label: 'sig', key: 'ehv_app_hud_release_sig_3', repeats: false, field_type: 'string' },
      { element_id: 11688, label: 'date', key: 'ehv_app_hud_release_date_3', repeats: false, field_type: 'string' },
      { element_id: 11689, label: 'date', key: 'ehv_app_hud_release_date_4', repeats: false, field_type: 'string' },
      { element_id: 11690, label: 'date', key: 'ehv_app_hud_release_date_5', repeats: false, field_type: 'string' },
      { element_id: 11708, label: 'Disability Status', key: 'ehv_app_disability_status', repeats: false, field_type: 'string' },
      { element_id: 11765, label: 'I,', key: 'ehv_app_cert_verification_delay_first_name', repeats: false, field_type: 'string' },
      { element_id: 11766, label: 'Last Name', key: 'ehv_app_cert_verification_delay_last_name', repeats: false, field_type: 'string' },
      { element_id: 11767, label: 'signature', key: 'ehv_app_cert_verification_delay_signature', repeats: false, field_type: 'string' },
      { element_id: 11768, label: 'date', key: 'ehv_app_cert_verification_delay_date', repeats: false, field_type: 'string' },
      { element_id: 11944, label: 'Head of Household Signature:', key: 'ehv_app_app_cert_head_of_household_signature', repeats: false, field_type: 'string' },
      { element_id: 11945, label: 'Head of Household Signature:', key: 'ehv_app_release_of_info_head_of_household_signature_1', repeats: false, field_type: 'string' },
      { element_id: 11946, label: 'Head of Household Signature:', key: 'ehv_app_hud_release_head_of_household_signature_1', repeats: false, field_type: 'string' },
      { element_id: 11990, label: 'Gender (HUD)', key: 'ehv_app_gender_hud', repeats: true, field_type: 'string' },
      { element_id: 11998, label: 'Name', key: 'ehv_app_asset_info_name_1', repeats: false, field_type: 'string' },
      { element_id: 11999, label: 'Source and Type', key: 'ehv_app_asset_info_source_and_type_1', repeats: false, field_type: 'string' },
      { element_id: 12000, label: 'Gross', key: 'ehv_app_asset_info_gross_1', repeats: false, field_type: 'string' },
      { element_id: 12001, label: 'Name', key: 'ehv_app_asset_info_name_2', repeats: false, field_type: 'string' },
      { element_id: 12002, label: 'Source and Type', key: 'ehv_app_asset_info_source_and_type_2', repeats: false, field_type: 'string' },
      { element_id: 12003, label: 'Gross', key: 'ehv_app_asset_info_gross_2', repeats: false, field_type: 'string' },
      { element_id: 12004, label: 'Name', key: 'ehv_app_asset_info_name_3', repeats: false, field_type: 'string' },
      { element_id: 12005, label: 'Source and Type', key: 'ehv_app_asset_info_source_and_type_3', repeats: false, field_type: 'string' },
      { element_id: 12006, label: 'Gross', key: 'ehv_app_asset_info_gross_3', repeats: false, field_type: 'string' },
      { element_id: 12007, label: 'Name', key: 'ehv_app_asset_info_name_4', repeats: false, field_type: 'string' },
      { element_id: 12008, label: 'Source and Type', key: 'ehv_app_asset_info_source_and_type_4', repeats: false, field_type: 'string' },
      { element_id: 12009, label: 'Gross', key: 'ehv_app_asset_info_gross_4', repeats: false, field_type: 'string' },
      { element_id: 12010, label: 'Name', key: 'ehv_app_asset_info_name_5', repeats: false, field_type: 'string' },
      { element_id: 12011, label: 'Source and Type', key: 'ehv_app_asset_info_source_and_type_5', repeats: false, field_type: 'string' },
      { element_id: 12012, label: 'Gross', key: 'ehv_app_asset_info_gross_5', repeats: false, field_type: 'string' },
      { element_id: 12035, label: 'name', key: 'ehv_app_income_verification_delay_name_1', repeats: false, field_type: 'string' },
      { element_id: 12036, label: 'name', key: 'ehv_app_income_verification_delay_name_2', repeats: false, field_type: 'string' },
      { element_id: 12037, label: 'name', key: 'ehv_app_income_verification_delay_name_3', repeats: false, field_type: 'string' },
      { element_id: 12038, label: 'name', key: 'ehv_app_income_verification_delay_name_4', repeats: false, field_type: 'string' },
      { element_id: 12039, label: 'name', key: 'ehv_app_income_verification_delay_name_5', repeats: false, field_type: 'string' },
      { element_id: 12040, label: 'source', key: 'ehv_app_income_verification_delay_source_1', repeats: false, field_type: 'string' },
      { element_id: 12041, label: 'source', key: 'ehv_app_income_verification_delay_source_2', repeats: false, field_type: 'string' },
      { element_id: 12042, label: 'source', key: 'ehv_app_income_verification_delay_source_3', repeats: false, field_type: 'string' },
      { element_id: 12043, label: 'source', key: 'ehv_app_income_verification_delay_source_4', repeats: false, field_type: 'string' },
      { element_id: 12044, label: 'source', key: 'ehv_app_income_verification_delay_source_5', repeats: false, field_type: 'string' },
      { element_id: 12045, label: 'pay', key: 'ehv_app_income_verification_delay_pay_1', repeats: false, field_type: 'string' },
      { element_id: 12046, label: 'pay', key: 'ehv_app_income_verification_delay_pay_2', repeats: false, field_type: 'string' },
      { element_id: 12047, label: 'pay', key: 'ehv_app_income_verification_delay_pay_3', repeats: false, field_type: 'string' },
      { element_id: 12048, label: 'pay', key: 'ehv_app_income_verification_delay_pay_4', repeats: false, field_type: 'string' },
      { element_id: 12049, label: 'pay', key: 'ehv_app_income_verification_delay_pay_5', repeats: false, field_type: 'string' },
      { element_id: 12050, label: 'hours', key: 'ehv_app_income_verification_delay_hours_1', repeats: false, field_type: 'string' },
      { element_id: 12051, label: 'hours', key: 'ehv_app_income_verification_delay_hours_2', repeats: false, field_type: 'string' },
      { element_id: 12052, label: 'hours', key: 'ehv_app_income_verification_delay_hours_3', repeats: false, field_type: 'string' },
      { element_id: 12053, label: 'hours', key: 'ehv_app_income_verification_delay_hours_4', repeats: false, field_type: 'string' },
      { element_id: 12054, label: 'hours', key: 'ehv_app_income_verification_delay_hours_5', repeats: false, field_type: 'string' },
      { element_id: 12055, label: 'monthly', key: 'ehv_app_income_verification_delay_monthly_1', repeats: false, field_type: 'string' },
      { element_id: 12056, label: 'monthly', key: 'ehv_app_income_verification_delay_monthly_2', repeats: false, field_type: 'string' },
      { element_id: 12057, label: 'monthly', key: 'ehv_app_income_verification_delay_monthly_3', repeats: false, field_type: 'string' },
      { element_id: 12058, label: 'monthly', key: 'ehv_app_income_verification_delay_monthly_4', repeats: false, field_type: 'string' },
      { element_id: 12059, label: 'monthly', key: 'ehv_app_income_verification_delay_monthly_5', repeats: false, field_type: 'string' },
      { element_id: 12066, label: 'inst.', key: 'ehv_app_assets_verification_delay_inst_1', repeats: false, field_type: 'string' },
      { element_id: 12067, label: 'inst.', key: 'ehv_app_assets_verification_delay_inst_2', repeats: false, field_type: 'string' },
      { element_id: 12068, label: 'inst.', key: 'ehv_app_assets_verification_delay_inst_3', repeats: false, field_type: 'string' },
      { element_id: 12069, label: 'inst.', key: 'ehv_app_assets_verification_delay_inst_4', repeats: false, field_type: 'string' },
      { element_id: 12070, label: 'inst.', key: 'ehv_app_assets_verification_delay_inst_5', repeats: false, field_type: 'string' },
      { element_id: 12071, label: 'name', key: 'ehv_app_assets_verification_delay_name_1', repeats: false, field_type: 'string' },
      { element_id: 12072, label: 'name', key: 'ehv_app_assets_verification_delay_name_2', repeats: false, field_type: 'string' },
      { element_id: 12073, label: 'name', key: 'ehv_app_assets_verification_delay_name_3', repeats: false, field_type: 'string' },
      { element_id: 12074, label: 'name', key: 'ehv_app_assets_verification_delay_name_4', repeats: false, field_type: 'string' },
      { element_id: 12075, label: 'name', key: 'ehv_app_assets_verification_delay_name_5', repeats: false, field_type: 'string' },
      { element_id: 12076, label: 'amount', key: 'ehv_app_assets_verification_delay_amount_1', repeats: false, field_type: 'string' },
      { element_id: 12077, label: 'amount', key: 'ehv_app_assets_verification_delay_amount_2', repeats: false, field_type: 'string' },
      { element_id: 12078, label: 'amount', key: 'ehv_app_assets_verification_delay_amount_3', repeats: false, field_type: 'string' },
      { element_id: 12079, label: 'amount', key: 'ehv_app_assets_verification_delay_amount_4', repeats: false, field_type: 'string' },
      { element_id: 12080, label: 'amount', key: 'ehv_app_assets_verification_delay_amount_5', repeats: false, field_type: 'string' },
      { element_id: 12093, label: 'name', key: 'ehv_app_id_verification_delay_name_1', repeats: false, field_type: 'string' },
      { element_id: 12094, label: 'name', key: 'ehv_app_id_verification_delay_name_2', repeats: false, field_type: 'string' },
      { element_id: 12095, label: 'name', key: 'ehv_app_id_verification_delay_name_3', repeats: false, field_type: 'string' },
      { element_id: 12096, label: 'name', key: 'ehv_app_id_verification_delay_name_4', repeats: false, field_type: 'string' },
      { element_id: 12097, label: 'name', key: 'ehv_app_id_verification_delay_name_5', repeats: false, field_type: 'string' },
      { element_id: 12098, label: 'name', key: 'ehv_app_id_verification_delay_name_6', repeats: false, field_type: 'string' },
      { element_id: 12099, label: 'name', key: 'ehv_app_id_verification_delay_name_7', repeats: false, field_type: 'string' },
      { element_id: 12100, label: 'name', key: 'ehv_app_id_verification_delay_name_8', repeats: false, field_type: 'string' },
      { element_id: 12101, label: 'name', key: 'ehv_app_id_verification_delay_name_9', repeats: false, field_type: 'string' },
      { element_id: 12102, label: 'name', key: 'ehv_app_id_verification_delay_name_10', repeats: false, field_type: 'string' },
      { element_id: 12103, label: 'name', key: 'ehv_app_id_verification_delay_name_11', repeats: false, field_type: 'string' },
    ].freeze

    def filename
      'ehv_application.xlsx'
    end

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "tc-ehv-app-#{response_id}"
    end

    def form_definition
      Hmis::Form::Definition.where(identifier: 'tc-ehv-app').first!
    end
  end
end