require "./MySQLDatabase"

class Appointment 
  
  attr_accessor :id, :start, :end, :title, :subject, :username

  def initialize(options={})
    self.id = options[:id]
    self.start = options[:start]
    self.end = options[:end]
    self.title = options[:title]
    self.subject = options[:subject]
    self.username = options[:username]
  end

  def fetch
    begin
      sql = "SELECT id, start, end, title, subject, username FROM appointment WHERE id = #{self.id} LIMIT 1"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)

      
      resp.each do |row|
        self.id = resp[0]['id']
        self.start = resp[0]['start']
        self.end = resp[0]['end']
        self.title = resp[0]['title']
        self.subject = resp[0]['subject']
        self.username = resp[0]['username']
      end
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch

  def post 
  	begin
      sql = "SELECT max(id) as max_id FROM appointment"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)
      next_id = resp[0]['max_id'] + 1

      sql = "INSERT INTO appointment (id, start, end, title, subject, username) VALUES (\"#{next_id}\",\"#{self.start}\", \"#{self.end}\", \"#{self.title}\", \"#{self.subject}\", \"#{self.username}\")"
      last_id = db.post(sql)
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end post

end # end class

#appt = Appointment.new(:id => "1")
#appt.fetch
#puts appt.inspect
