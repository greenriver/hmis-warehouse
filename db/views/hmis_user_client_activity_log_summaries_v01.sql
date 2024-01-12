SELECT
	CONCAT(hmis_activity_logs_clients.client_id, ':', hmis_activity_logs.user_id) AS id,
	MAX(hmis_activity_logs.created_at) AS last_accessed_at,
	hmis_activity_logs_clients.client_id AS client_id,
	hmis_activity_logs.user_id AS user_id
FROM
	hmis_activity_logs
	JOIN hmis_activity_logs_clients ON hmis_activity_logs_clients.activity_log_id = hmis_activity_logs.id
GROUP BY
	hmis_activity_logs_clients.client_id,
	hmis_activity_logs.user_id
