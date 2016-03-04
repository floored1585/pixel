# description_event.rb
#
require_relative 'component_status_event'

class DescriptionEvent < ComponentStatusEvent


  def self.friendly_subtype
    'Description'
  end


  def html_details(component=nil)
    if @hw_type == 'Interface' && component
      details = "Description for #{@hw_type} #{component.name} on #{@device} changed from \"#{@old}\" to \"#{@new}\""
    else
      details = "Description for #{@hw_type} #{@index} on #{@device} changed from \"#{@old}\" to \"#{@new}\""
    end
    return details
  end


  def get_email(db)
    component = Component.fetch_from_db(device: @device, hw_types: ["#{@hw_type}"], index: @index, db: db).first
    is_interface = component.hw_type == "Interface"

    subject = "Description Change! #{component.hw_type} "
    if is_interface
      # Use interface name if it's an interface
      subject << "#{component.name} "
    else
      # Use Component index if it's not an interface
      subject << "#{component.index} "
    end
    subject << "on #{component.device} (#{@new})"

    body = "Device: #{component.device}\n"
    body << "Component: #{component.hw_type}\n"
    body << "Index: #{component.index}\n"
    body << "Name: #{component.name}\n" if is_interface
    body << "\n"
    body << "New Description: #{@new}\n"
    body << "Old Description: #{@old}\n"

    {
      subject: subject,
      body: body
    }
  end


end
