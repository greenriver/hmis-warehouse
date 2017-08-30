class SourceClientsController < Window::SourceClientsController

  def redirect_to_path
    client_path(@destination_client)
  end
end