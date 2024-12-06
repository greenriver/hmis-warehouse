CREATE TRIGGER prevent_delete_client_searchable_names
    INSTEAD OF DELETE ON public.client_searchable_names
    FOR EACH ROW
    EXECUTE FUNCTION prevent_modification();
