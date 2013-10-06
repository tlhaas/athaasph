require "./MySQLDatabase"
require "json"

class Customer
  
  attr_accessor :id, :givenname, :middlename, :surname, :birthdate, :addresses, :phone_numbers, :links

  def initialize(options={})
    self.id             = options[:id]
    self.givenname      = options[:givenname]
    self.middlename     = options[:middlename]
    self.surname        = options[:surname]
    self.birthdate      = options[:birthdate]
    self.addresses      = options[:addresses] 
    self.phone_numbers  = options[:phone_numbers]
    self.links          = Hash.new
  end

  # formerly getCustomer
  def fetch
    begin
      sql = "SELECT * FROM customer WHERE id = '#{self.id}' LIMIT 1"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)

      resp.each do |row|
        self.id = resp[0]['id']
        self.givenname = resp[0]['givenname']
        self.middlename = resp[0]['middlename']
        self.surname = resp[0]['surname']
        self.birthdate = resp[0]['birthdate']
      end

      sql2 = "SELECT id, street_1, street_2, city, state, zip, country, type FROM address WHERE customer_id = '#{self.id}'"
      resp2 = db.get(sql2)
      self.addresses = resp2

      sql3 = "SELECT phone_number, type FROM phone where customer_id = '#{self.id}'"
      resp3 = db.get(sql3)
      self.phone_numbers = resp3

      self.links["home"]          = Hash["href" => "/"]
      self.links["self"]          = Hash["href" => "/customer/#{self.id}"]
      self.links["edit"]          = Hash["href" => "/customer/#{self.id}"]
      self.links["delete"]        = Hash["href" => "/customer/#{self.id}"]
      self.links["customer_list"] = Hash["href" => "/customer"]

    rescue Exception => e
      raise e.message
    ensure
      db.close
    end # end begin
  end # end fetch

  def post
    begin
      sql 	= "SELECT max(id) as max_id FROM customer"
      db = MySQLDatabase.new
      db.connect
      resp 	= db.get(sql)
      next_id = resp[0]["max_id"] + 1

      sql = "INSERT INTO customer (id, givenname, middlename, surname, last_updated) VALUES (\"#{next_id}\", \"#{self.givenname}\", \"#{self.middlename}\", \"#{self.surname}\", \"#{Time.now.to_i}\")"
      resp = db.post(sql)

      self.id = resp

      if self.addresses.size > 0
        self.addresses.each do |address|
          street_1	= address["street_1"]
          street_2 	= address["street_2"]
          city 		= address["city"]
          state		= address["state"]
          zip 		= address["zip"]
          country 	= address["country"]
          type 		= address["type"]

          sql 	= "INSERT INTO address (customer_id, street_1, street_2, city, state, zip, country, type, last_updated) VALUES (\"#{self.id}\", \"#{street_1}\",\"#{street_2}\",\"#{city}\",\"#{state}\",\"#{zip}\",\"#{country}\",\"#{type}\",\"#{Time.now.to_i}\")"
          resp 	= db.post(sql)
        end
      end

      if self.phone_numbers.size > 0
        self.phone_numbers.each do |phone_number|
          the_num 	= phone_number["phone_number"]
          the_type 	= phone_number["type"]

          sql 	= "INSERT INTO phone (customer_id, phone_number, type, last_updated) VALUES (\"#{self.id}\", \"#{the_num}\", \"#{the_type}\",\"#{Time.now.to_i}\")"
          resp 	= db.post(sql) 
        end
      end

      self.links["home"]          = Hash["href" => "/"]
      self.links["self"]          = Hash["href" => "/customer/#{self.id}"]
      self.links["edit"]          = Hash["href" => "/customer/#{self.id}"]
      self.links["delete"]        = Hash["href" => "/customer/#{self.id}"]
      self.links["customer_list"] = Hash["href" => "/customer"]
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end 
  end # end post 

  def put 
    begin
      sql = "UPDATE customer SET givenname='#{self.givenname}', middlename='#{self.middlename}', surname='#{self.surname}', last_updated='#{Time.now.to_i}' WHERE id='#{self.id}'"
      db = MySQLDatabase.new
      db.connect
      updated = db.put(sql) # true or false

      if updated
        sql = "DELETE FROM phone WHERE customer_id='#{self.id}'"
        deleted = db.delete(sql)

        self.phone_numbers.each do |the_number|
          phone_number 	= the_number['phone_number']
          type 			= the_number['type']

          sql = "INSERT INTO phone (customer_id, phone_number, type) VALUES (\"#{self.id}\", \"#{phone_number}\", \"#{type}\")"
          num_rows = db.put(sql)
        end

        sql = "DELETE FROM address WHERE customer_id='#{self.id}'"
        delete = db.delete(sql)

        self.addresses.each do |the_address|
          street_1 	= the_address['street_1']
          street_2 	= the_address['street_2']
          city 		= the_address['city']
          state 		= the_address['state']
          zip 		= the_address['zip']
          country 	= the_address['country']
          type 		= the_address['type']

          sql = "INSERT INTO address (customer_id, street_1, street_2, city, state, zip, country, type) VALUES (\"#{self.id}\",\"#{street_1}\",\"#{street_2}\",\"#{city}\",\"#{state}\",\"#{zip}\",\"#{country}\",\"#{type}\")"
          num_rows = db.put(sql)	  
        end
      end # if end
    rescue Exception => e
      raise e.message
    ensure 
      db.close
    end
  end # end put

  def delete
    begin
      sql = "DELETE FROM customer WHERE id = '#{self.id}'"
      db = MySQLDatabase.new
      db.connect
      deleted = db.delete(sql)

      sql = "DELETE FROM phone WHERE customer_id = '#{self.id}'"
      deleted = db.delete(sql)

      sql = "DELETE FROM address WHERE customer_id = '#{self.id}'"
      deleted = db.delete(sql)

    rescue Exception => e
      raise e.message
    ensure
      db.close
    end 
  end # end delete

  def to_hash
    # :id, :givenname, :middlename, :surname, :birthdate, :addresses, :phone_numbers, :links
    customer = {
      "_links" => self.links,
      "id" => self.id,
      "givenname" => self.givenname,
      "middlename" => self.middlename,
      "surname" => self.surname,
      "birthdate" => self.birthdate,
      "addresses" => self.addresses,
      "phone_numbers" => self.phone_numbers
    }
  end

  def to_hal
    JSON.pretty_generate( self.to_hash )
  end
end # Customer end

# test for delete
=begin
customer = Customer.new(:id => "20")
puts customer.inspect
customer.delete
# check database
=end

# test for put 
=begin
customer = Customer.new(:id => "1")
customer.fetch
puts customer.inspect
fone_1 = [{"phone_number"=>"555-BONER", "type"=>"cell"}]
customer.phone_numbers = fone_1
puts customer.inspect
customer.put
# change details
# customer.put
# see if it worked
=end

# fetch test
=begin
customer = Customer.new(:id => "1")
customer.fetch
puts customer.to_hal
#puts customer.inspect
=end

# post test
=begin
addr_1 = {"street_1" => "123 boner street", "street_2"=>"", "city"=>"Bonerville", "state"=>"KY", "country"=>"US", "type"=>"home"}
fone_1 = {"phone_number"=>"555-BONER", "type"=>"cell"}
phone_numbers = [ fone_1 ]
addresses = [ addr_1 ]

options = {
	:givenname => "Louie",
	:middlename => "The Dude",
	:surname => "CK",
	:birthday => "",
	:addresses => addresses,
	:phone_numbers => phone_numbers
}

customer = Customer.new(options)

customer.post
puts customer.inspect
=end