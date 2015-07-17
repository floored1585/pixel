# description_event.rb
#
require_relative 'component_status_event'

class DescriptionEvent < ComponentStatusEvent

  def html_details(component=nil)
    if @hw_type == 'Interface' && component
      details = "Description for #{@hw_type} #{component.name} on #{@device} changed from \"#{@old}\" to \"#{@new}\""
    else
      details = "Description for #{@hw_type} #{@index} on #{@device} changed from \"#{@old}\" to \"#{@new}\""
    end
    return details
  end

end
