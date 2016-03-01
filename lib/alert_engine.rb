# alert_engine.rb
#
require 'logger'
$LOG ||= Logger.new(STDOUT)

module AlertEngine


  def self.process_events(db)
    alerts = []
    events = Event.get_unprocessed
    events.each do |event|
      alert = event.get_alert
      alerts.push alert if alert
      #event.process!.save(db)
    end
  end


  def self.process_alerts
  end


end
