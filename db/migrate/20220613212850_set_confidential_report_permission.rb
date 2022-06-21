class SetConfidentialReportPermission < ActiveRecord::Migration[6.1]
   def up
     # The can_report_on_confidential_projects defaults to false
     # for existing roles that can see confidential enrollments
     # let them also see confidential projects within reports
     Role.where(can_view_confidential_project_names: true).
       update_all(can_report_on_confidential_projects: true)
   end
 end
