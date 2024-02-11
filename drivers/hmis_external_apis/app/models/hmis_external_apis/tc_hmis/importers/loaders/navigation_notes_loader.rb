###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# todays_urgency_and_options

module HmisExternalApis::TcHmis::Importers::Loaders
  class NavigationNotesLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_CONFIGS = [
      { element_id: 7313,
        label: 'Are you assigned to a housing Navigator?',
        key: 'nav_are_you_assigned_to_a_housing_navigator',
        repeats: false,
        field_type: 'string' },
      { element_id: 7316, label: 'Case Notes', key: 'nav_case_notes', repeats: false, field_type: 'string' },
      { element_id: 7356, label: 'Navigator.', key: 'nav_navigator', repeats: false, field_type: 'string' },
      { element_id: 7357,
        label: 'Did the client show up for appointment?',
        key: 'nav_did_the_client_show_up_for_appointment',
        repeats: false,
        field_type: 'string' },
      { element_id: 7358, label: 'Is this an attempt to contact?', key: 'nav_is_this_an_attempt_to_contact', repeats: false, field_type: 'string' },
      { element_id: 7871, label: 'Time Spent', key: 'nav_time_spent', repeats: false, field_type: 'string' },
      { element_id: 8487, label: 'Type of Client Interaction', key: 'nav_type_of_client_interaction', repeats: false, field_type: 'string' },
      { element_id: 8841,
        label: 'Problem Solving/Diversion/Rapid Resolution intervention or service result - Client housed/re-housed in a safe alternative',
        key: 'nav_key_8841',
        repeats: false,
        field_type: 'string' },
      { element_id: 8842, label: 'Referral Result', key: 'nav_referral_result', repeats: false, field_type: 'string' },
      { element_id: 8843,
        label: 'Referral to post-placement/follow-up case management result - Enrolled in Aftercare project',
        key: 'nav_key_8843',
        repeats: false,
        field_type: 'string' },
      { element_id: 8845, label: 'Date of Event', key: 'nav_date_of_event', repeats: false, field_type: 'string' },
      { element_id: 8846, label: 'Date of result', key: 'nav_date_of_result', repeats: false, field_type: 'string' },
      { element_id: 10586, label: 'Services Rendered', key: 'nav_services_rendered', repeats: true, field_type: 'string' },
      { element_id: 10587, label: 'Other Services', key: 'nav_other_services', repeats: false, field_type: 'string' },
      { element_id: 10588,
        label: 'Primary Point of Contact for Housing match',
        key: 'nav_primary_point_of_contact_for_housing_match',
        repeats: false,
        field_type: 'string' },
      { element_id: 10674, label: 'Event', key: 'nav_event', repeats: false, field_type: 'string' },
      { element_id: 10675,
        label: 'Where you able to divert the client?',
        key: 'nav_where_you_able_to_divert_the_client',
        repeats: false,
        field_type: 'string' },
    ].freeze

    def filename
      'navigation_notes.xlsx'
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
      "nav-eto-#{response_id}"
    end

    def form_definition
      Hmis::Form::Definition.where(identifier: 'navigation-notes').first!
    end


  end
end
