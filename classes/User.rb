require "digest"
require "./MySQLDatabase"

class User

	attr_accessor :id, :customer_id, :username, :auth, :password, :links

	def initialize(options={})
	  self.id 					= options[:id]
	  self.customer_id 	= options[:customer_id]
	  self.username 		= options[:username]
	  self.auth 				= options[:auth]
	  self.password 		= options[:password]
	  self.links 				= Hash.new
	end

	# formerly getUser
	def fetch()
	  begin
	    sql = "SELECT id, customer_id, username, auth, password FROM user WHERE id = #{self.id} LIMIT 1"
			db = MySQLDatabase.new()
			db.connect
			resp = db.get(sql)

			resp.each do |row|
		  	self.id = resp[0]['id']
		  	self.customer_id = resp[0]['customer_id']
		  	self.username = resp[0]['username']
		  	self.auth = resp[0]['auth']
		  	self.password = resp[0]['password']
	    end

	    # Resource links
	   	self.links["delete"] 					= Hash["href" => "/user/#{self.id}", "title" => "Delete User"]
	   	self.links["update_password"] = Hash["href" => "/user/#{self.id}", "title" => "Update Password"]
	   	self.links["update_username"] = Hash["href" => "/user/#{self.id}", "title" => "Update Username"]
	   	self.links["update_auth"] 		= Hash["href" => "/user/#{self.id}", "title" => "Update Auth"]
	   	self.links["user_list"] 			= Hash["href" => "/user"]
	   	self.links["home"] 						= Hash["href" => "/"]

	  rescue Exception => e
			raise e.message
	  ensure
			db.close
	  end
	end

	# formerly createUser
	def post()
	  begin
	    hashed_password = Digest::SHA1.hexdigest(self.password)
			sql = "SELECT max(id) as max_id FROM user"
			db 	= MySQLDatabase.new()
			db.connect
			resp 	= db.get(sql)
			next_id = resp[0]["max_id"] + 1

			if self.customer_id
		  	sql = "INSERT INTO user (id, customer_id, username, password, auth) VALUES (\"#{next_id}\", \"#{self.customer_id}\", \"#{self.username}\", \"#{hashed_password}\", \"#{self.auth}\")"
			else
		  	sql = "INSERT INTO user (id, username, password, auth) VALUES (\"#{next_id}\", \"#{self.username}\", \"#{self.password}\", \"#{self.auth}\")"
			end
			insert_id = db.post(sql)
			self.id 	= insert_id

	    # Resource links
	   	self.links["delete"] 					= Hash["href" => "/user/#{self.id}", "title" => "Delete User"]
	   	self.links["update_password"] = Hash["href" => "/user/#{self.id}", "title" => "Update Password"]
	   	self.links["update_username"] = Hash["href" => "/user/#{self.id}", "title" => "Update Username"]
	   	self.links["update_auth"] 		= Hash["href" => "/user/#{self.id}", "title" => "Update Auth"]
	   	self.links["user_list"] 			= Hash["href" => "/user"]
	   	self.links["home"] 						= Hash["href" => "/"]

	  rescue Exception => e
			raise e.message
	  ensure
			db.close		
	  end
	end

	def update_password()
	  hashed_password = Digest::SHA1.hexdigest(self.password)
	  begin
			sql = "UPDATE user SET password='#{hashed_password}' WHERE id='#{self.id}'"
			db = MySQLDatabase.new()
			db.connect
			resp = db.put(sql)
	  rescue Exception => e
			raise e.message
	  ensure
			db.close
	  end
	end

	def update_username()
	  begin 
			sql = "UPDATE user SET username='#{self.username}' WHERE id='#{self.id}'"
			db = MySQLDatabase.new()
			db.connect
			num_rows_affected = db.put(sql)
	  rescue Exception => e
			raise e.message
	  ensure
			db.close
	  end
	end

	def update_auth()
	  begin
			sql = "UPDATE user SET auth='#{self.auth}' WHERE id='#{self.id}'"
			db = MySQLDatabase.new()
			db.connect
			num_rows_affected = db.put(sql)
	  rescue Exception => e
			raise e.message
	  ensure
			db.close
	  end
	end

	def delete()
	  begin
			sql = "DELETE FROM user WHERE id='#{id}'"
			db = MySQLDatabase.new()
			db.connect
			num_rows_affected = db.delete(sql)
	  rescue Exception => e
			raise e.message
	  ensure
			db.close
	  end
	end

	def to_hash
		#attr_accessor :id, :customer_id, :username, :auth, :password, :links
		user = {
			"_links" => self.links,
			"id" => self.id,
			"customer_id" => self.customer_id,
			"username" => self.username,
			"auth" => self.auth
		}
	end

	def to_hal
		JSON.pretty_generate( self.to_hash )
	end

end

#------------------------------------------------#

#
# delete
# 

=begin
begin
	user = User.new(:id => "7")
	puts user.delete
rescue Exception => e
	puts e.message
end
=end

#------------------------------------------------#

#
# put
# 

=begin
begin
	user = User.new(:id => "1")
	user.fetch()
	puts user.inspect
	puts "Auth before: #{user.auth}"
	user.auth = "admin"
	user.update_auth()
	user.fetch()
	puts "Auth after: #{user.auth}"
rescue Exception => e
	puts e.message
end
=end

#------------------------------------------------#

#
# get
# 


=begin
	user = User.new(:id => "1")
	user.fetch()
	puts user.to_hal
rescue Exception => e
	puts "Banana boobs"
=end 


#------------------------------------------------#

#
# post
# 
=begin
user_deets = {
	:username 	=> "Larry Pants Dude 5.0",
	:password 	=> "Penistits",
	:auth 		=> "admin"
}

begin 
	user = User.new(user_deets)
	user.post()
rescue Exception => e
	puts "404, bro"
end

puts user.inspect
=end