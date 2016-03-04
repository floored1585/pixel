# alert_engine.rb
#
require 'logger'
$LOG ||= Logger.new(STDOUT)

module AlertEngine


  def self.process_events(db, config)
    events = Event.get_unprocessed

    alerts_enabled = config.alerts_enabled.value
    recipients = config.alert_recipients.value
    from_name = config.alert_from_name.value
    from_email = config.alert_from_email.value

    # Construct the 'from' field
    from_field = ""
    unless from_email.empty?
      from_field << from_name
      from_field << " <" unless from_name.empty?
      from_field << from_email
      from_field << ">" unless from_name.empty?
    end

    if recipients.empty?
      $LOG.warn "ALERT_ENGINE: Alerts enabled, but no recipients defined!"
    end

    if from_field.empty?
      $LOG.warn "ALERT_ENGINE: Alerts enabled, but no source email address defined!"
    end

    events.each do |event|
      # Mark event as processed, so we don't process it again next time
      event.process!.save(db)

      mail_data = event.get_email(db)

      # Move on to next event if any of these conditions aren't met.
      # We have to 'next' instead of 'break' because we need to mark
      # events as processed even if these conditions prevent emails
      # from going out.
      next unless alerts_enabled && mail_data
      next if from_field.empty? || recipients.empty?

      # Send the email!
      begin
        Mail.deliver do
          from     from_field
          to       recipients
          subject  mail_data[:subject]
          body     mail_data[:body]
        end
      rescue Net::SMTPFatalError => e
        $LOG.error "ALERT_ENGINE: Error sending alert email: #{e}"
      end

    end
  end


end
