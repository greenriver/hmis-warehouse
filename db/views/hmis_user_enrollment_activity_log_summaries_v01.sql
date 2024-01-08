SELECT
	CONCAT(hmis_activity_logs_enrollments.enrollment_id, ':', hmis_activity_logs.user_id) AS id,
	MAX(hmis_activity_logs.created_at) AS last_accessed_at,
	hmis_activity_logs_enrollments.enrollment_id AS enrollment_id,
	hmis_activity_logs_enrollments.project_id AS project_id,
	hmis_activity_logs.user_id AS user_id
FROM
	hmis_activity_logs
	JOIN hmis_activity_logs_enrollments ON hmis_activity_logs_enrollments.activity_log_id = hmis_activity_logs.id
GROUP BY
	hmis_activity_logs_enrollments.enrollment_id,
	hmis_activity_logs_enrollments.project_id,
	hmis_activity_logs.user_id
