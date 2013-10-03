require "./Job"
require "./MySQLDatabase"

class Jobs

  attr_accessor :collection, :job_type, :page_num

  def initialize(job_type = 0, page_num = 1)
    self.collection = Array.new
    self.job_type = job_type
    self.page_num = page_num
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
      resp.each do |row|
        job = Job.new
        job.id = row['id']
        job.date = row['date']
        job.job_type = row['job_type']
        job.givenname = row['givenname']
        job.middlename = row['middlename']
        job.surname = row['surname']
        job.total = row['total']
        self.collection.push(job)
      end
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch

end


#jobs = Jobs.new(3, 2)
#jobs.fetch()
#puts jobs.inspect