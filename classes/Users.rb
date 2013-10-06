require "./MySQLDatabase"
require "./User"
require "json"

class Users
  attr_accessor :collection, :links

  def initialize
  	self.collection = Array.new
    self.links = {
      "home" => Hash["href" => "/"],
      "self" => Hash["href" => "/user"],
      "new" => Hash["href" => "/user"]
    }
  end

  # formerly getUsers()
  def fetch()	  
    begin
      sql = "SELECT id, customer_id, auth, username FROM user"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)

      resp.each do |row|
        user = User.new
        user.id = row['id']
        user.customer_id = row['customer_id']
        user.username = row['username']
        user.auth = row['auth']
        user.password = row['password']	

        user.links["delete"]          = Hash["href" => "/user/#{user.id}", "title" => "Delete User"]
        user.links["update_password"] = Hash["href" => "/user/#{user.id}", "title" => "Update Password"]
        user.links["update_username"] = Hash["href" => "/user/#{user.id}", "title" => "Update Username"]
        user.links["update_auth"]     = Hash["href" => "/user/#{user.id}", "title" => "Update Auth"]
        user.links["user_list"]       = Hash["href" => "/user"]
        user.links["home"]            = Hash["href" => "/"]

        self.collection.push(user)
      end
    rescue Exception => e
      raise e.message
    ensure 
      db.close
    end
  end # end fetch

  def to_hal
    hashd_users = Array.new
    self.collection.each do |user|
      hashd_users.push(user.to_hash)
    end
    hal = Hash.new
    hal["_links"] = self.links
    hal["_embedded"] = { "users" => hashd_users }
    JSON.pretty_generate( hal )
  end

end # end class



#users = Users.new
#users.fetch
#puts users.to_hal
#users.collection.each do |user|
#  puts user.inspect
#end