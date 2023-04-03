class MoveDashboardPermissions < ActiveRecord::Migration[5.2]
  def up
    # Disabled with addition of ACSs
    #  return unless Role.column_names.include?('can_view_censuses')

    #   # Directly assign report access to anyone who had access via can_view_censuses previously
    #  urls = [
    #    'dashboards/adult_only_households',
    #    'dashboards/adults_with_children',
    #    'dashboards/clients',
    #    'dashboards/child_only_households',
    #    'dashboards/non_veterans',
    #    'dashboards/veterans',
    #    'censuses',
    #  ]
    #  census_reports = GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: urls)
    #  User.joins(:roles).merge(Role.where(can_view_censuses: true)).distinct.select(:id, :email).find_each do |user|
    #    census_reports.each do |report|
    #      user.add_viewable(report)
    #    end
    #  end
   end
end
