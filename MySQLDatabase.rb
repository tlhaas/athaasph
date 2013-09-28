require 'mysql2'
require 'digest'

class MySQLDatabase

	attr_accessor :host, :port, :username, :password, :database, :connection

	def initialize(host='127.0.0.1', port=8889, username='root', password='root', database='athaasph')
	  self.host 	= host
	  self.port 	= port
	  self.username = username
	  self.password = password
	  self.database	= database
	end # end initialize

	def connect
	  self.connection = Mysql2::Client.new(:host => self.host, :port => self.port, :username => self.username, :password => self.password, :database => self.database);
	end # end connect

	def close 
	  self.connection.close
	end

	# Select
	def get(sql)
	  begin
		results = self.connection.query(sql)
		resp	= Array.new
		results.each do |row|
		  resp.push(row)
		end
	  rescue Mysql2::Error => e
		raise e.message
		# log errors in the future
	  end

	  return resp
	end # end get

	# Insert
	def post(sql)
	  begin
		results = self.connection.query(sql)
		last_id = self.connection.last_id
	  rescue Mysql2::Error => e
		raise e.message
		nil
	  end
	end

	# Update
	def put(sql)
	  begin 
		results 	= self.connection.query(sql)
		num_rows 	= self.connection.affected_rows
	  rescue Mysql2::Error => e
		raise e.message
	  end

	  if num_rows >= 1
		return true
	  else
		return false
	  end
	end

	# Delete 
	def delete(sql)
	  begin 
		results 	= self.connection.query(sql)
		num_rows 	= self.connection.affected_rows
	  rescue MySQL2::Error => e
		raise e.message
	  end

	  if num_rows >= 1
		return true
	  else
		return false
	  end
	end

end # end class

#
#------------------------------------------------------------------#
#

# Let's try it out now
=begin
db 		= MySQLDatabase.new()
db.connect
	
	resp 	= db.get("SELECT max(id) as max_id FROM user")
	next_id = resp[0]["max_id"] + 1

	username		= "Fat Tits 4.0"
	hashed_password = Digest::SHA1.hexdigest("sandynips")
	auth 			= "admin"

	resp 	= db.post("INSERT INTO user (id, username, password, auth) VALUES (\"#{next_id}\", \"#{username}\", \"#{hashed_password}\", \"#{auth}\")")
	puts "Insert ID: " + resp.inspect

	new_username 	= "Fat Tits 12.0"
	user_id 		= next_id
	resp 	= db.put("UPDATE user SET username='#{new_username}' WHERE id='#{user_id}'")
	puts "Username updated? " + resp.inspect

	id = next_id
	resp 	= db.delete("DELETE FROM user WHERE id='#{id}'")
	puts "User deleted? " + resp.inspect

db.close
=end