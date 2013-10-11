require "./classes/MySQLDatabase"
require "json"

class Job

  attr_accessor :id, :date, :customer_id, :addr_id, :job_type, :total, :memo, :givenname, :middlename, :surname, :street_1, :street_2, :city, :state, :zip, :country, :type, :line_items, :payments, :links

  def initialize(options={})
    self.id           = options[:id]
    self.date         = options[:date]
    self.customer_id  = options[:customer_id]
    self.addr_id      = options[:addr_id]
    self.job_type     = options[:job_type]
    self.total        = options[:total]
    self.memo         = options[:memo]
    self.givenname    = options[:givenname]
    self.middlename   = options[:middlename]
    self.surname      = options[:surname]
    self.street_1     = options[:street_1]
    self.street_2     = options[:street_2]
    self.city         = options[:city]
    self.state        = options[:state]
    self.zip          = options[:zip]
    self.country      = options[:country]
    self.type         = options[:type]
    self.line_items   = options[:line_items]
    self.payments     = options[:payments]
    self.links        = Hash.new
  end

  def fetch
    begin
      sql = "SELECT j.date, j.customer_id, j.addr_id, j.job_type, j.total, j.memo, c.givenname, c.middlename, c.surname, a.street_1, a.street_2, a.city, a.state, a.zip, a.country, a.type
       FROM job as j LEFT JOIN address as a ON j.addr_id = a.id
        JOIN customer as c ON j.customer_id = c.id
       WHERE j.id = '#{self.id}' LIMIT 1" 

      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)

      if resp.empty?
        raise "Job not found!"
      end
      
      self.date = resp[0]['date']
      self.customer_id = resp[0]['customer_id']
      self.addr_id = resp[0]['addr_id']
      self.job_type = resp[0]['job_type']
      self.total = resp[0]['total']
      self.memo = resp[0]['memo']
      self.givenname = resp[0]['givenname']
      self.middlename = resp[0]['middlename']
      self.surname = resp[0]['surname']
      self.street_1 = resp[0]['street_1']
      self.street_2 = resp[0]['street_2']
      self.city = resp[0]['city']
      self.state = resp[0]['state']
      self.country = resp[0]['country']
      self.type = resp[0]['type']

      sql = "SELECT item_type, note, rate, rate_quantity, is_taxable
      FROM line_item
      WHERE job_id = '#{self.id}'"

      resp = db.get(sql)
      self.line_items = resp

      sql = "SELECT type, amount, date, note FROM payment WHERE job_id = '#{self.id}'"
      resp = db.get(sql)
      self.payments = resp

      self.links["home"]      = Hash["href" => "/"]
      self.links["self"]      = Hash["href" => "/job/#{self.id}"]
      self.links["edit"]      = Hash["href" => "/job/#{self.id}"]
      self.links["delete"]    = Hash["href" =>"/job/#{self.id}"]
      self.links["job_list"]  = Hash["href" =>"/job"]

    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch

  def post 
    begin
      sql   = "SELECT max(id) as max_id FROM job"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)
      next_id = resp[0]['max_id'] + 1

      sql = "INSERT INTO job (id, date, customer_id, addr_id, total, memo, job_type) VALUES (\"#{next_id}\", \"#{self.date}\", \"#{self.customer_id}\", \"#{self.addr_id}\", \"#{self.total}\", \"#{self.memo}\", \"#{self.job_type}\")"
      last_id = db.post(sql)

      self.id = last_id

      self.line_items.each do |line_item|
        item_type     = line_item["item_type"]
        note          = line_item["note"]
        rate          = line_item["rate"]
        rate_quantity = line_item["rate_quantity"]
        is_taxable    = line_item["is_taxable"]

        sql     = "INSERT INTO line_item (job_id, item_type, note, rate, rate_quantity, is_taxable) VALUES (\"#{self.id}\", \"#{item_type}\", \"#{note}\", \"#{rate}\", \"#{rate_quantity}\", \"#{is_taxable}\")"
        db.post(sql)  
      end

      self.links["home"]      = Hash["href" => "/"]
      self.links["self"]      = Hash["href" => "/job/#{self.id}"]
      self.links["edit"]      = Hash["href" => "/job/#{self.id}"]
      self.links["delete"]    = Hash["href" =>"/job/#{self.id}"]
      self.links["job_list"]  = Hash["href" =>"/job"]

    rescue Exception => e
      raise e.stacktrace
    ensure
      db.close
    end
  end

  def put
    begin
      sql = "UPDATE job SET date='#{self.date}', customer_id='#{self.customer_id}', addr_id='#{self.addr_id}', job_type='#{self.job_type}', total='#{self.total}', last_updated='#{Time.now.to_i}', memo='#{self.memo}' WHERE id = '#{self.id}'"
      db = MySQLDatabase.new
      db.connect

      updated = db.put(sql)

      if updated
        sql = "DELETE FROM line_item WHERE job_id = '#{self.id}'"
        deleted_line_items = db.delete(sql)

        if deleted_line_items
          self.line_items.each do |line_item|
            item_type     = line_item["item_type"]
            note          = line_item["note"]
            rate          = line_item["rate"]
            rate_quantity = line_item["rate_quantity"]
            is_taxable    = line_item["is_taxable"]

            sql     = "INSERT INTO line_item (job_id, item_type, note, rate, rate_quantity, is_taxable) VALUES (\"#{self.id}\", \"#{item_type}\", \"#{note}\", \"#{rate}\", \"#{rate_quantity}\", \"#{is_taxable}\")"
            db.put(sql)  
          end
        end

        if self.payments.length > 0
          sql = "DELETE FROM payment WHERE job_id='#{self.id}'"
          deleted_payments = db.delete(sql)

          if deleted_payments
            payments.each do |payment|
              type  = payment['type']
              amount  = payment['amount']
              date    = payment['date']
              note  = payment['note']

              sql = "INSERT INTO payment (job_id, type, amount, date, note) VALUE (\"#{self.id}\", \"#{type}\", \"#{amount}\", \"#{date}\", \"#{note}\")"
              db.put(sql)
            end # end payments insert loop
          end 
        end
      end
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end

  def to_hash
    # attr_accessor :id, :date, :customer_id, :addr_id, :job_type, :total, :memo, :givenname, :middlename, :surname, 
    # :street_1, :street_2, :city, :state, :zip, :country, :type, :line_items, :payments, :links
    job = {
      "_links" => self.links,
      "id" => self.id,
      "date" => self.date,
      "customer_id" => self.customer_id,
      "addr_id" => self.addr_id,
      "job_type" => self.job_type,
      "total" => self.total,
      "memo" => self.memo,
      "givenname" => self.givenname,
      "middlename" => self.middlename,
      "surname" => self.surname,
      "street_1" => self.street_1,
      "street_2" => self.street_2,
      "city" => self.city,
      "state" => self.state,
      "zip" => self.zip,
      "country" => self.country,
      "type" => self.type,
      "line_items" => self.line_items,
      "payments" => self.payments,
    }

    # Delete null values
    #job.each do |key,value|
    #  job.delete(key) if value.nil?
    #end
  end # end to_hash

  def to_hal
    JSON.pretty_generate( self.to_hash )
  end # end to_hal

end # end class


#
# Put test
#
=begin
job = Job.new(:id => 39)
job.fetch
job.job_type = "2"
job.put
=end


#
# Post test
#
=begin
line_items = [{
  "item_type" => "Labor",
  "note" => "I did something",
  "rate" => "100",
  "rate_quantity" => "1",
  "is_taxable" => "1"
}]

options = {
  :date => "10-03-2013",
  :customer_id => "2",
  :addr_id => "24",
  :total => "107",
  :memo => "Some thing happen, so I get 100 doll hairs.",
  :job_type => "1",
  :line_items => line_items
}


job = Job.new(options)
job.post
=end

#
# Get test
#
=begin
job = Job.new(:id => 30)
job.fetch

puts job.to_hal
=end

# puts job.inspect