require "./MySQLDatabase"
require "./Customer"
require "json"

class Customers 

  attr_accessor :collection 

  def initialize
    self.collection = Array.new
  end

  def fetch 
    begin
      sql = "SELECT id, givenname, middlename, surname, birthdate FROM customer"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)
      
      resp.each do |row|
        customer = Customer.new
        customer.id = row['id']
        customer.givenname = row['givenname']
        customer.middlename = row['middlename']
        customer.surname = row['surname']
        customer.birthdate = row['birthdate']
        self.collection.push(customer)
      end
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch 

end

#customer_list = Customers.new
#customer_list.fetch
#puts customer_list.inspect