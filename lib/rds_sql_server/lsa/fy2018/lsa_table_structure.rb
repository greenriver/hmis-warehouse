SqlServerBase.connection.execute (<<~SQL);
  #{File.read('lib/rds_sql_server/lsa/fy2018/LSADictionaryTables.sql')}
SQL
SqlServerBase.connection.execute (<<~SQL);
  SET ANSI_NULLS ON
SQL
SqlServerBase.connection.execute (<<~SQL);
  SET QUOTED_IDENTIFIER ON
SQL
SqlServerBase.connection.execute (<<~SQL);
  #{File.read('lib/rds_sql_server/lsa/fy2018/LSAIntermediateTables.sql')}
SQL

