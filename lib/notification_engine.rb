#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# notification_engine.rb
#
require 'logger'
require_relative 'helper'

$LOG ||= Logger.new(STDOUT)

module NotificationEngine

  def self.process_events(db, config)
    events = Event.get_unprocessed

    notifications_enabled = config.notifications_enabled.value
    recipients = config.notification_recipients.value
    from_name = config.notification_from_name.value
    from_email = config.notification_from_email.value
    notify_types = config.event_notify_types.value

    unless notify_types.is_a? Array
      $LOG.error "NOTIFICATION ENGINE: event_notify_types is not an Array!"
      notify_types = []
    end

    # Construct the 'from' field
    from_field = ""
    unless from_email.empty?
      from_field << from_name
      from_field << " <" unless from_name.empty?
      from_field << from_email
      from_field << ">" unless from_name.empty?
    end

    if notifications_enabled && recipients.empty?
      $LOG.warn "NOTIFICATION_ENGINE: Notifications enabled, but no recipients defined!"
    end

    if notifications_enabled && from_field.empty?
      $LOG.warn "NOTIFICATION_ENGINE: Notifications enabled, but no source email address defined!"
    end

    email_count = 0

    events.each do |event|
      # Mark event as processed, so we don't process it again next time
      event.process!.save(db)

      mail_data = event.get_email(db)

      # Move on to next event if any of these conditions aren't met.
      # We have to 'next' instead of 'break' because we need to mark
      # events as processed even if these conditions prevent emails
      # from going out.
      next unless notifications_enabled && mail_data && notify_types.include?(event.class.to_s)
      next if from_field.empty? || recipients.empty?

      # Send the email!
      begin
        Mail.deliver do
          from     from_field
          to       recipients
          subject  mail_data[:subject]
          body     mail_data[:body] + "\n\n#{Helper.device_url(config, event.device)}"
        end

        email_count += 1

      rescue Net::SMTPFatalError => e
        $LOG.error "ALERT_ENGINE: Error sending notification email: #{e}"
      end

    end

    $LOG.info "NOTIFICATION_ENGINE: Successfully processed #{events.size} events" if events.size > 0
    $LOG.info "NOTIFICATION_ENGINE: Successfully sent #{email_count} emails" if email_count > 0

  end


end
