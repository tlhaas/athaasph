require "rubygems"
require "bundler/setup"

require 'sinatra'
require 'json'
require './classes/Appointments'
require './classes/Customers'
require './classes/Jobs'
require './classes/Users'

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
  
	if appts.collection.length > 0
    appts.to_hal
  else
	  halt 404
	end
end

=begin
post "/appointment" do
	current_time = Time.now.to_i*1000

	token = request.env['HTTP_AUTHORIZATION']
	token = Token.new(token)
	token.decode
	
	request.body.rewind  # in case someone already read it
	appt 		= JSON.parse request.body.read	
  	title 		= appt['title']
  	subject 	= appt['subject']
  	start 		= appt['start']
  	finish 		= appt['end']
  	username 	= token.username

  	if start <= current_time
  		msg = Hash["message" => "You can't make make a reservation in the past."]
  		halt 409, Hash["error" => msg].to_json
  	else
		resp = create_appointment(title, subject, start, finish, username)
	end

	resp.to_json(JSON_FORMAT)

end 

=end 
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

=begin
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
  			hashed_password = Digest::SHA1.hexdigest(val)	
  			resp = update_password(hashed_password, "#{params[:id]}")
  			if resp.nil? || resp == 0
  				halt 400
  			else
  				status 204
  			end
  		elsif /username/.match(data['replace'])
  			resp = update_username(val, "#{params[:id]}")
  			if resp.nil? || resp == 0
  				halt 400
  			else
  				status 204
  				# could return 200 and updated Resource too
  				#headers \
  				#	"Location" => "http://localhost:4567/user/#{params[:id]}"
  			end
  		elsif /auth/.match(data['replace'])
  			resp = update_auth(val, "#{params[:id]}")
  			if resp.nil? || resp == 0
  				halt 400
  			else
  				status 204
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

  	resp = create_user(username, password, cust_id, auth)
  	if resp.nil?
  		halt 404
  	else
  		resp.to_json(JSON_FORMAT)
  	end
end

delete '/user/:id' do
	resp = delete_user("#{params[:id]}")
	if resp.nil?
		halt 4040
	else
		status 204
	end
end
=end 
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

=begin
post '/customer' do 

	#customer 		= JSON.parse("#{params[:customer]}")
	request.body.rewind  # in case someone already read it
  	customer = JSON.parse request.body.read
	givenname 		= customer["givenname"]
	middlename 		= customer["middlename"]
	surname 		= customer["surname"]
    phone_numbers 	= customer["phone_numbers"]
    addresses  		= customer["addresses"]

    resp = create_customer(givenname, middlename, surname, phone_numbers, addresses)
    resp.to_json(JSON_FORMAT)
end

put '/customer/:id' do
	request.body.rewind  # in case someone already read it
  	customer = JSON.parse request.body.read
	#customer 		= JSON.parse("#{params[:customer]}")
	customer_id 	= customer["id"]
	givenname 		= customer["givenname"]
	middlename 		= customer["middlename"]
	surname 		= customer["surname"]
    phone_numbers 	= customer["phone_numbers"]
    addresses  		= customer["addresses"]

    resp = update_customer(customer_id, givenname, middlename, surname, phone_numbers, addresses)
	
	if resp == nil
		status 400
	else
		status 204
	end
end
=end

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

=begin
post '/job' do
	
	# need to turn line_items into a hash
	#job 		= JSON.parse("#{params[:job]}")
	request.body.rewind  # in case someone already read it
  	job = JSON.parse request.body.read
	
	line_items 	= job["line_items"]
	client_id	= job["client_id"]
	client_addr = job["addr_id"]
	date 		= job["date"]
	total		= job["total"]
	memo		= job["memo"]
	job_type	= job["job_type"]

	resp = create_new_job( line_items, client_id, client_addr, date, total, memo, job_type )

	resp.to_json(JSON_FORMAT)
end

put '/job/:id' do
	#data = request.body.read
	#params.inspect

	request.body.rewind  # in case someone already read it
  	job = JSON.parse request.body.read

	#job 		= JSON.parse("#{params[:job]}")
	job_id 		= job["job_id"]
	customer_id = job["customer_id"]
	addr_id		= job["addr_id"]
	date 		= job["date"]
	total		= job["total"]
	line_items  = job["line_items"]
	memo		= job["memo"]
	job_type	= job["job_type"]
	payments 	= job["payments"]

	resp = update_job( job_id, customer_id, addr_id, date, total, line_items, memo, job_type, payments )

	if resp == nil
		status 400
	else
		status 204
	end
	#resp.to_json(JSON_FORMAT)
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
	ip_addr 	= "#{request.ip}"

	resp		= authenticate_user(username, password, ip_addr)

	if resp.nil?
		halt 404
	end
	resp.to_json(JSON_FORMAT)
end

# valid a token you have
get '/token/:the_token' do
	token 	= "#{params[:the_token]}"
	
  	resp = authenticate_token(token)

	if resp.nil?
		halt 404
	end
	resp.to_json(JSON_FORMAT)
end

=end