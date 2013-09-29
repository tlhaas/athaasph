require "./MySQLDatabase"
require "./User"
require "json"

class Users
  attr_accessor :collection

  def initialize
  	self.collection = Array.new
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
        self.collection.push(user)
      end
    rescue Mysql2::Error => e
      raise e.message
    ensure 
      db.close
    end
  end # end fetch

end # end class



users = Users.new
users.fetch
users.collection.each do |user|
  puts user.inspect
end