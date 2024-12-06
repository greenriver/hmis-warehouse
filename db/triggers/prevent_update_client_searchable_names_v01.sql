CREATE TRIGGER prevent_update_client_searchable_names
    INSTEAD OF UPDATE ON public.client_searchable_names
    FOR EACH ROW
    EXECUTE FUNCTION prevent_modification();
