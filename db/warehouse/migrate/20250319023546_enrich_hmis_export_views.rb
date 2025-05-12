# frozen_string_literal: true

class EnrichHmisExportViews < ActiveRecord::Migration[7.0]
  def up
    update_view('analytics.exits', version: 2)
    new_views.each do |view|
      create_view(view)
    end
  end

  def down
    update_view('analytics.exits', version: 1)
    new_views.each { |view| drop_view(view) }
  end

  def new_views
    [
      'analytics.client_geolocations',
      'analytics.hmis_case_notes',
      'analytics.hmis_external_form_submissions',
      'analytics.hmis_staff_assignments',
      'analytics.hmis_client_alerts',
    ]
  end
end
