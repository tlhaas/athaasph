require "./classes/MySQLDatabase"
require "./classes/Customer"
require "json"

class Customers 

  attr_accessor :collection, :links

  def initialize
    self.collection = Array.new
    self.links = {
      "home"    => Hash["href" => "/"],
      "self"    => Hash["href" => "/customer"],
      "new"     => Hash["href" => "/customer"],
      "filters" => {
        "item"        => Hash["href" => "/customer/{id}"]
      }
    }
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
        customer.links["home"]          = Hash["href" => "/"]
        customer.links["self"]          = Hash["href" => "/customer/#{customer.id}"]
        customer.links["edit"]          = Hash["href" => "/customer/#{customer.id}"]
        customer.links["delete"]        = Hash["href" => "/customer/#{customer.id}"]
        customer.links["customer_list"] = Hash["href" => "/customer"]
        self.collection.push(customer)
      end
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch 

  def to_hal
    hashd_customers = Array.new
    self.collection.each do |customer|
      hashd_customers.push(customer.to_hash)
    end
    hal = Hash.new
    hal["_links"] = self.links
    hal["_embedded"] = { "customer" => hashd_customers }
    JSON.pretty_generate( hal )

  end


end

#customer_list = Customers.new
#customer_list.fetch
#puts customer_list.to_hal