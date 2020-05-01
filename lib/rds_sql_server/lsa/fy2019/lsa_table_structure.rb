steps = [
  'lib/rds_sql_server/lsa/fy2019/sample_code/1 Create Temp Reporting and Reference Tables.sql',
  'lib/rds_sql_server/lsa/fy2019/sample_code/2_1 to 2_10 Create Output Tables.sql',
]
SqlServerBase.connection.execute <<~SQL
  SET ANSI_NULLS ON
SQL
SqlServerBase.connection.execute <<~SQL
  SET QUOTED_IDENTIFIER ON
SQL
steps.each do |file|
  query = File.read(file).gsub(/^GO/, '')
  SqlServerBase.connection.execute <<~SQL
    #{query}
  SQL
  GrdaWarehouseBase.connection.reconnect!
  ApplicationRecord.connection.reconnect!
  ReportingBase.connection.reconnect!
end
