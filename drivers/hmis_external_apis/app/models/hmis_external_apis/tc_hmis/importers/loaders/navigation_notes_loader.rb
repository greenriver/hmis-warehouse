###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class NavigationNotesLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_CONFIGS = [
      { element_id: 7316, label: 'Case Notes', key: 'nav_notes_case_note', repeats: false, field_type: 'string' },
      { element_id: 7871, label: 'Time Spent', key: 'nav_notes_time_spent', repeats: false, field_type: 'string' },
      { element_id: 8487, label: 'Type of Client Interaction', key: 'nav_notes_interaction_type', repeats: false, field_type: 'string' },
      { element_id: 10586, label: 'Services Rendered', key: 'nav_notes_services_rendered', repeats: true, field_type: 'string' },
      { element_id: 10587, label: 'Other Services', key: 'nav_notes_other_services', repeats: false, field_type: 'string' },
      { element_id: 10588, label: 'Primary Point of Contact for Housing match', key: 'nav_notes_primary_contact', repeats: false, field_type: 'boolean' },
      { element_id: 10675, label: 'Were you able to divert the client?', key: 'nav_notes_diverted', repeats: false, field_type: 'boolean' },
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
      Hmis::Form::Definition.where(identifier: 'tc-nav-notes').first!
    end
  end
end
