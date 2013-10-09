require "./classes/MySQLDatabase"
require "json"

class Appointment 
  
  attr_accessor :id, :start, :end, :title, :subject, :username, :allDay, :links

  def initialize(options={})
    self.id = options[:id]
    self.start = options[:start]
    self.end = options[:end]
    self.title = options[:title]
    self.subject = options[:subject]
    self.username = options[:username]
    self.allDay = false
    self.links = Hash.new
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
      self.links            = Hash.new
      self.links["self"]    = Hash["href" => "/appointment/#{self.id}", "title" => "Self"]
      self.links["delete"]  = Hash["href" => "/appointment/#{self.id}", "title" => "Delete Appointment"]

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
      self.id = last_id

      self.links            = Hash.new
      self.links["self"]    = Hash["href" => "/appointment/#{self.id}", "title" => "Self"]
      self.links["delete"]  = Hash["href" => "/appointment/#{self.id}", "title" => "Delete Appointment"]

    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end post

  def to_hash
    appt = {
      "_links" => self.links,
      "id" => self.id,
      "start" => self.start,
      "end" => self.end,
      "title" => self.title,
      "subject" => self.subject,
      "username" => self.username,
      "allDay" => self.allDay
    }
  end

  def to_hal
    JSON.pretty_generate( self.to_hash )
  end

end # end class

#appt = Appointment.new(:id => "1")
#appt.fetch
#puts appt.to_hal
#puts JSON.dump(appt)
