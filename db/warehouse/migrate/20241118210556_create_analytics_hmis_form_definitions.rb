class CreateAnalyticsHmisFormDefinitions < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.hmis_form_definitions"
  end
end
