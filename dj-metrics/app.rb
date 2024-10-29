# frozen_string_literal: true

require 'sinatra'

get '/healthz' do
  'ok'
end

get '/*' do
  redirect '/metrics'
end
