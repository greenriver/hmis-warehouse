class SourceClientsController < Window::SourceClientsController
  include ClientPathGenerator
  def redirect_to_path
    client_path(@destination_client)
  end
end