require 'sinatra'

get '/' do
  @title = "Index"
  erb :index
end