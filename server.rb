require "rubygems"
require "bundler/setup"

require 'sinatra'
require 'json'
require './classes/Appointments'
require './classes/Customers'
require './classes/Jobs'
require './classes/Users'
require './classes/Token'

# SSL
# http://stackoverflow.com/questions/3696558/how-to-make-sinatra-work-over-https-ssl
# http://stackoverflow.com/questions/11405161/enable-ssl-in-sinatra-with-thin
# http://bytesofpi.com/post/28952453059/forcing-ssl-in-a-sinatra-app
# http://blog.divebomb.org/2012/01/ruby-sinatra-and-ssl/

before do
	#content_type "application/HAL+json"
	
	# don't require authorization header with token for token routes
	#unless request.path_info =~ /(\/token|\/appointment).*/
	#	puts request.path_info
	#	token = request.env['HTTP_AUTHORIZATION']
	#	if token.nil?
	#		halt 469
	#	end
	#	token = Token.new(token)
	#	token.decode
	#	if (!token.is_valid)
	#		halt 470
	#	end 
	#end
end

# 
# Root 
#

get "/" do
	resp = {
    "_links" => {
      "self"              => { "href" => "/" },
      "customer_list"     => { "href" => "/customer" },
      "user_list"         => { "href" => "/user" }, 
      "job_list"          => { "href" => "/job" },
      "appointment_list"  => { "href" => "/appointment" }
    }
  }
  resp.to_json
end

#
# Appointment
#

# http://localhost:4567/appointment?start=1378618200000&finish=1378731600000
get "/appointment" do
	start 	= params["start"]
	finish 	= params["finish"]

	if start.nil? || finish.nil?
		halt 400
	end

  appts = Appointments.new
  appts.fetchVerbose(start,finish)
  appts.to_hal
end

post "/appointment" do
  begin
  	current_time = Time.now.to_i*1000

  	#token = request.env['HTTP_AUTHORIZATION']
  	#token = Token.new(token)
  	#token.decode
  	
  	request.body.rewind  # in case someone already read it
  	appt 		= JSON.parse request.body.read	
    	title 		= appt['title']
    	subject 	= appt['subject']
    	start 		= appt['start']
    	finish 		= appt['end']
    	username 	= "jones" # token.username

    options = {
      :start => start,
      :end => finish,
      :title => title,
      :subject => subject,
      :username => username
    }

    if start <= current_time
    	msg = Hash["message" => "You can't make make a reservation in the past."]
    	halt 409, Hash["error" => msg].to_json
    else
      new_appoinment = Appointment.new(options)
      new_appoinment.post
      new_appoinment.to_hal
  	end
  rescue Exception => e
    halt 404
  end
end 

#
# User
#

get '/user' do
  users = Users.new
  users.fetch
  if users.collection.length > 0
    users.to_hal
  else 
    halt 404
  end
end

get '/user/:id/?' do
  begin
    user = User.new(:id => "#{params[:id]}")
    user.fetch()
    user.to_hal
  rescue Exception => e
    halt 404
  end
end


patch '/user/:id' do
	halt 415 unless request.media_type == "application/json-patch+json"

	request.body.rewind  # in case someone already read it
	data = JSON.parse request.body.read
	add = data['add']
	val = data['value']

	if data['add']
		return "You wanna add something!? #{val}"
	elsif data['remove']
		return "You wanna remove something?! #{val}"
	elsif data['replace']	
		if /password/.match(data['replace'])
      
      begin
        options = Hash[:id => "#{params[:id]}", :password => val]
        user = User.new(options)
        user.update_password
        status 204
      rescue Exception => e
        halt 409
      end
		elsif /username/.match(data['replace'])
      begin 
        options = Hash[:id => "#{params[:id]}", :username => val]
        user = User.new(options)
        user.update_username
        status 204
      rescue Exception => e
        halt 409
      end
		elsif /auth/.match(data['replace'])
      begin 
        options = Hash[:id => "#{params[:id]}", :auth => val]
        user = User.new(options)
        user.update_auth
        status 204
      rescue Exception => e
        halt 409
      end
		else
			# you're trying to replace something that doesn't exist
			halt 400  			
		end
	elsif data['move']
		return "You wanna move something!? #{val}"
	elsif data['test']
		return "You wanna test something!? #{val}"
	end	
end

post '/user' do 
	request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  username = data['username']
  password = data['password']
  cust_id  = data['customer_id']
  auth   	 = data['auth']

  user_deets = {
    :username => username,
    :password => password,
    :auth     => auth
  }

  begin 
    user = User.new(user_deets)
    user.post()
    user.to_hal
  rescue Exception => e
    halt 409
  end
  
end

delete '/user/:id' do
  begin
    user = User.new(:id => "#{params[:id]}")
    if (user.delete)
      status 204
    else
      status 409
    end
  rescue Exception => e
    halt 404
  end
end

#
# Customer
#


get '/customer' do
	customer_list = Customers.new
  customer_list.fetch

  if customer_list.collection.length > 0
    customer_list.to_hal
  else
    halt 404
  end
end

get '/customer/:id/?' do
  begin
    customer = Customer.new(:id => "#{params[:id]}")
    customer.fetch
    customer.to_hal
  rescue Exception => e
    halt 404
  end
end

post '/customer' do 
  begin
    request.body.rewind  # in case someone already read it
    customer      = JSON.parse request.body.read
    givenname     = customer["givenname"]
    middlename    = customer["middlename"]
    surname       = customer["surname"]
    phone_numbers = customer["phone_numbers"]
    addresses     = customer["addresses"]

    options = {
      :givenname => givenname,
      :middlename => middlename,
      :surname => surname,
      :addresses => addresses,
      :phone_numbers => phone_numbers
    }

    new_customer = Customer.new(options)
    new_customer.post
    new_customer.to_hal
  rescue Exception => e
    halt 404
  end
	
end

put '/customer/:id' do
  begin	
    request.body.rewind  # in case someone already read it
    customer = JSON.parse request.body.read

  	customer_id 	= customer["id"]
  	givenname 		= customer["givenname"]
  	middlename 		= customer["middlename"]
  	surname 		  = customer["surname"]
    phone_numbers = customer["phone_numbers"]
    addresses  	  = customer["addresses"]

    options = {
      :id            => customer_id,
      :givenname     => givenname,
      :middlename    => middlename,
      :surname       => surname,
      :addresses     => addresses,
      :phone_numbers => phone_numbers
    }
    customer = Customer.new(options)
    customer.put
    status 204
  rescue Exception => e
    halt 400
  end
end


#
# Job
#


get '/job' do
  job_type = 0
  if params[:page]
    page = "#{params[:page]}" 
  else
    page = 1
  end

  begin
    jobs = Jobs.new(job_type.to_i, page.to_i)
    jobs.fetch
    jobs.to_hal
  rescue Exception => e
    halt 404
  end
end


get '/job/proposals' do
	job_type = 1
  if params[:page]
    page = "#{params[:page]}" 
  else
    page = 1
  end

  begin
    jobs = Jobs.new(job_type.to_i, page.to_i)
    jobs.fetch
    jobs.to_hal
  rescue Exception => e
    halt 404
  end
end

get '/job/work_orders' do
	job_type = 2
  if params[:page]
    page = "#{params[:page]}" 
  else
    page = 1
  end

  begin
    jobs = Jobs.new(job_type.to_i, page.to_i)
    jobs.fetch
    jobs.to_hal
  rescue Exception => e
    halt 404
  end
end

get '/job/invoices' do
	job_type = 3
  if params[:page]
    page = "#{params[:page]}" 
  else
    page = 1
  end

  begin
    jobs = Jobs.new(job_type.to_i, page.to_i)
    jobs.fetch
    jobs.to_hal
  rescue Exception => e
    halt 404
  end
end

get '/job/:id' do
  begin
    job = Job.new(:id => "#{params[:id]}")
    job.fetch
    job.to_hal
  rescue Exception => e 
    halt 404
  end
end


post '/job' do
	
	request.body.rewind  # in case someone already read it
  job = JSON.parse request.body.read
  	line_items  = job["line_items"]
    client_id   = job["client_id"]
    client_addr = job["addr_id"]
    date        = job["date"]
    total       = job["total"]
    memo        = job["memo"]
    job_type    = job["job_type"]

  options = {
    :date => date,
    :customer_id => client_id,
    :addr_id => client_addr,
    :total => total,
    :memo => memo,
    :job_type => job_type,
    :line_items => line_items
  }

  begin
    job = Job.new(options)
    job.post
    job.to_hal
  rescue Exception => e
    halt 404
  end

end


put '/job/:id' do
	request.body.rewind  # in case someone already read it
  job          = JSON.parse request.body.read
	 job_id 		 = job["job_id"]
	 customer_id = job["customer_id"]
	 addr_id		 = job["addr_id"]
	 date 		   = job["date"]
	 total		   = job["total"]
	 line_items  = job["line_items"]
	 memo		     = job["memo"]
	 job_type	   = job["job_type"]
	 payments    = job["payments"]

  begin
    options = {
      :id => job_id,
      :customer_id => customer_id,
      :addr_id => addr_id,
      :date => date,
      :total => total,
      :line_items => line_items,
      :memo => memo,
      :job_type => job_type,
      :payments => payments
    }
    job = Job.new(options)
    job.put
    status 204
  rescue Exception => e
    e.message.to_json
  end
end


#
# Token
#

# get a new token
post '/token' do
  request.body.rewind
  data = JSON.parse request.body.read

  username 	= data['username']
  password 	= data['password']
  ip_addr 	  = "#{request.ip}"

  begin
    token = Token.new(username, password, ip_addr)
    token.encode
    das_token = token.to_s
    das_token.to_json
  rescue Exception => e
    halt 404
  end
end

# validate a token you have
get '/token/:the_token' do
	#token 	= "#{params[:the_token]}"
	
	token = Token.new(params[:the_token])
  token.decode
  
  if (token.username.nil? || token.auth.nil? || token.timestamp.nil? || token.ip_addr.nil?)
    halt 404
  else
    token.to_hal
  end
end