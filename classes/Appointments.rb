require "./classes/MySQLDatabase"
require "./classes/Appointment"

class Appointments
  
  attr_accessor :collection, :links

  def initialize
    self.collection = Array.new
    self.links = {
      "home" => Hash["href" => "/"],
      "self" => Hash["href" => "/appointment"],
      "new" => Hash["href" => "/appointment"]
    }
    # 10/06/2013
    # no idea why I'd need a template on collections.
    # revisit this
    # "template" => Hash["href" => "/appointment/?"],
  end 

  def fetchVerbose(start,stop)
    begin
      sql = "SELECT id, start, end, title, subject, username FROM appointment WHERE start >= #{start} AND end <= #{stop}"
      db = MySQLDatabase.new
      db.connect
      resp = db.get(sql)

      resp.each do |row|
        appt = Appointment.new
        appt.id = row['id']
        appt.start = row['start']
        appt.end = row['end']
        appt.title = row['title']
        appt.subject = row['subject']
        appt.username = row['username']
        # Individual Resource links
        appt.links["self"]    = Hash["href" => "/appointment/#{appt.id}", "title" => "Self"]
        appt.links["delete"]  = Hash["href" => "/appointment/#{appt.id}", "title" => "Delete Appointment"]
        self.collection.push(appt)
      end

    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetchVerbose

  def to_hal
    hashd_appts = Array.new
    self.collection.each do |appt|
      hashd_appts.push(appt.to_hash)
    end
    hal = Hash.new
    hal["_links"] = self.links
    hal["_embedded"] = { "appointment" => hashd_appts }
    JSON.pretty_generate( hal )
  end # end to_hal

end

#appts = Appointments.new
#appts.fetchVerbose("1378618200000","1378731600000")
#puts appts.to_hal
#puts appts.collection.length