require "./MySQLDatabase"
require "./Appointment"

class Appointments
  
  attr_accessor :collection

  def initialize
    self.collection = Array.new
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

        self.collection.push(appt)
      end
    rescue Exception => e
      raise e.message
    ensure
      db.close
    end
  end # end fetch

end

#appts = Appointments.new
#appts.fetchVerbose("1378618200000","1378731600000")
#puts appts.collection.length