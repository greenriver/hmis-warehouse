class CreateAnalyticsHmisFormProcessors < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.hmis_form_processors'
  end
end
