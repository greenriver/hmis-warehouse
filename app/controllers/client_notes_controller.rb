class ClientsController < ApplicationController
  def new
    @client_note = ClientNote.new
  end
end
