require 'sinatra'
require 'sinatra/json'
require 'bcrypt'
require 'securerandom'
require './my_user_model' # This should load the User model
require 'sqlite3'

# Configuration
# secret_key = '6f2d4b5e8a1c7d903bc5f8a6e9d4c3f0b6a2e7c8f9d0a1b2c3d4e5f6a7b8c9d0'
# enable :sessions
# set :session_secret, secret_key

configure do
  set :session_store, Rack::Session::Cookie
  set :sessions, secure: true, httponly: true
  set :bind, '0.0.0.0'
  set :port, 8080

  enable :sessions
  set :session_secret, SecureRandom.hex(64)  # Generate a secure session secret

  set :static, true
  set :public_folder, File.expand_path('../views', __FILE__)

  puts "Static dir: #{settings.public_folder}"
  puts "__FILE__: #{__FILE__}"
  puts "File.dirname: #{File.dirname(__FILE__)}"
end

helpers do
  def user_model
    @user_model ||= User.new
  end

  def hash_password(password)
    BCrypt::Password.create(password)
  end

  def verify_password(hashed_password, password)
    BCrypt::Password.new(hashed_password) == password
  end
end

# Routes
before do
  content_type :json
end

get '/users' do
  users = user_model.all
  users.each { |user| user.delete(:password) }
  json users
end

post '/users' do
  user_info = {
    firstname: params[:firstname],
    lastname: params[:lastname],
    age: params[:age],
    password: hash_password(params[:password]),
    email: params[:email]
  }
  puts "User Info: #{user_info.inspect}"
  user_id = user_model.create(user_info)
  user = user_model.find(user_id)
  user.delete('password')
  json user
end

post '/sign_in' do
  email = params[:email]
  password = params[:password]

  if email.nil? || password.nil?
    status 400
    return json(message: 'Email and password are required')
  end

  begin
    users = user_model.all
    puts "All Users: #{users.inspect}"
    user = user_model.find_by_email(email)
    puts "Retrieved User: #{user.inspect}"

    if user && verify_password(user['password'], password)
      session[:user_id] = user['id']
      user.delete('password')
      json user
    else
      status 401
      json(message: 'Invalid email or password')
    end
  rescue StandardError => e
    status 500
    json(message: 'An error occurred', error: e.message)
  end
end

put '/users' do
  if session[:user_id]
    user_id = session[:user_id]
    new_password = params[:new_password]

    if new_password.nil? || new_password.strip.empty?
      status 400
      return json({ error: 'New password cannot be empty' })
    end

    hashed_password = hash_password(new_password)
    user = user_model.update(user_id, 'password', hashed_password)

    if user
      user.delete('password')
      json user
    else
      status 500
      json({ error: 'Failed to update user password' })
    end
  else
    status 401
  end
end

delete '/sign_out' do
  halt 401, 'Unauthorized' unless session[:user_id]
  session.clear
  status 204
end

delete '/users' do
  if session[:user_id]
    user_id = session[:user_id]
    user_model.destroy(user_id)
    session.clear
    status 204
  else
    status 401
    json(message: 'Unauthorized')
  end
end

# get '/' do
#   send_file File.join(settings.public_folder, 'index.html')
# end

get '/' do
  @users = user_model.all
  erb :index
end