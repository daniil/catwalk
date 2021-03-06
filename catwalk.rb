require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'

enable :sessions

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource
  property :id, Serial
  property :username, String, :required => true, :unique => true
  property :password, String, :required => true
  property :account_type, Integer, :default => 0
  property :created_at, DateTime
end
DataMapper.finalize.auto_upgrade!

get '/' do
  @title = "Index"
  erb :index
end

get '/register' do
  @title = "Register"
  erb :register
end

post '/register' do
  hashed_password = Digest::MD5.hexdigest(params[:password])
  user = User.new(:username => params[:username], :password => hashed_password)
  if user.save
    flash[:success] = "Profile successfully created"
    redirect "/profile"
  else
    flash[:error] = "User already exists"
    redirect "/register"
  end
end

get '/login' do
  @title = "Login"
  erb :login
end

post '/login' do
  hashed_password = Digest::MD5.hexdigest(params[:password])
  user = User.first(:username => params[:username], :password => hashed_password)
  if user
    flash[:success] = "Logged in successfully as #{user.username}"
    session[:user_id] = user.id
    redirect "/profile"
  else
    flash[:error] = "Wrong credentials"
    redirect "/login"
  end
end

get '/profile' do
  @title = "Profile Information"
  if session.id
    @user = User.get session[:user_id]
    erb :profile
  else
    flash[:error] = "You have to log in to use the site"
    redirect "/login"
  end
end

# Admin section
get '/admin/users' do
  @title = "Users"
  @users = User.all :order => :id.asc
  erb :admin_users, :layout => :admin
end

get '/admin/users/new' do
  @title = "Create new user"
  erb :admin_users_new, :layout => :admin
end

post '/admin/users/new' do
  hashed_password = Digest::MD5.hexdigest(params[:password])
  user = User.new(:username     => params[:username], 
                  :password     => hashed_password,
                  :account_type => params[:account_type])
  if user.save
    redirect "/admin/users"
  else
    "User already exists"
  end
end

get '/admin/users/:id/delete' do
  @title = "Delete user"
  @user = User.get params[:id]
  erb :admin_users_delete, :layout => :admin
end

delete '/admin/users/:id/delete' do
  user = User.get params[:id]
  if user.destroy
    redirect "/admin/users"
  else
    "Couldn't delete the user"
  end
end