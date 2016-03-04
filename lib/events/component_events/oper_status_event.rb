# oper_status_event.rb
#
require_relative 'component_status_event'

class OperStatusEvent < ComponentStatusEvent


  def self.friendly_subtype
    'Link Status'
  end


  def html_details(int=nil)
    if @new == 'Down'
      status_class = 'text-danger'
      verb = 'went'
    else # Up
      status_class = 'text-success'
      verb = 'came'
    end

    if int
      "Interface #{int.name} on #{@device} #{verb} <span class='#{status_class}'><b>#{@new}</b></span>"
    else
      "Interface w/ index #{@index} on #{@device} #{verb} <span class='#{status_class}'><b>#{@new}</b></span>"
    end
  end


  def get_email(db)
    int = Component.fetch_from_db(device: @device, hw_types: ["Interface"], index: @index, db: db).first
    {
      subject: "Interface Oper #{@new}: #{int.name} on #{@device}",
      body: ""
    }
  end


end
