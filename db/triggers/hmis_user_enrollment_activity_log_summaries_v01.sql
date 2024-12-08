CREATE TRIGGER hmis_user_enrollment_activity_log_summaries
    INSTEAD OF UPDATE ON public.client_searchable_names
    FOR EACH ROW
    EXECUTE FUNCTION prevent_modification();
