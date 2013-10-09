require "./classes/Job"
require "./classes/MySQLDatabase"
require "json"

class Jobs

  attr_accessor :collection, :job_type, :page_num, :links

  def initialize(job_type = 0, page_num = 1)
    self.collection = Array.new
    self.job_type = job_type
    self.page_num = page_num
    self.links = {
      "home" => Hash["href", "/"],
      "new" => Hash["href", "/job"],
      "filters" => {
        "proposals"   => Hash["href" => "/job/proposals"],
        "work_orders" => Hash["href" => "/job/work_orders"],
        "invoices"    => Hash["href" => "/job/invoices"],
        "all"         => Hash["href" => "/job"]
      }
    }
  end

  def fetch
    begin  
      set_size  = 25;                             # max number of records to return
      start     = (page_num.to_i - 1) * set_size; # row in the database to start with

      sql = "SELECT job.id, job.date, job.job_type, customer.givenname, customer.middlename, customer.surname, job.is_paid, job.total 
        FROM job JOIN customer ON job.customer_id = customer.id"
      sql += " WHERE job.job_type = '#{self.job_type}'" unless self.job_type == 0
      sql += " LIMIT #{start}, #{set_size+1}"

      db = MySQLDatabase.new
      db.connect

      resp = db.get(sql)

      if resp.empty?
        raise "No jobs found!"
      end 

      resp.each do |row|
        job = Job.new
        job.id = row['id']
        job.date = row['date']
        job.job_type = row['job_type']
        job.givenname = row['givenname']
        job.middlename = row['middlename']
        job.surname = row['surname']
        job.total = row['total']
        job.links["home"]      = Hash["href" => "/"]
        job.links["self"]      = Hash["href" => "/job/#{job.id}"]
        job.links["edit"]      = Hash["href" => "/job/#{job.id}"]
        job.links["delete"]    = Hash["href" =>"/job/#{job.id}"]
        job.links["job_list"]  = Hash["href" =>"/job"]
        self.collection.push(job)
      end

      #### Generate collection links ####
      case self.job_type                 
        when 1
          uri_stub = "/job/proposals"
        when 2
          uri_stub = "/job/work_orders"
        when 3
          uri_stub = "/job/invoices"
        else
          uri_stub = "/job"
      end

      # Find the next link, if it's there
      if self.collection.length > set_size
        while self.collection.length > set_size do
          self.collection.pop
        end
        self.links["next"] = Hash["href" => "#{uri_stub}?page=#{page_num.to_i + 1}"]
      end

      # Find the previous link, if it's there
      if page_num.to_i > 1
        self.links["prev"] = Hash["href" => "#{uri_stub}?page=#{page_num.to_i - 1}"]
      end 

      # Find the current link
      if page_num > 1
        self.links["self"] = Hash["href" => "#{uri_stub}?page=#{page_num.to_i}"]
      else
        self.links["self"] = Hash["href" => "#{uri_stub}"]
      end

    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch

  def to_hal
    hashd_jobs = Array.new
    self.collection.each do |job|
      hashd_jobs.push(job.to_hash)
    end
    hal = Hash.new
    hal["_links"] = self.links
    hal["_embedded"] = { "job" => hashd_jobs }
    JSON.pretty_generate( hal )
  end # end to_hal

end


#jobs = Jobs.new(2)
#jobs.fetch
#puts jobs.to_hal