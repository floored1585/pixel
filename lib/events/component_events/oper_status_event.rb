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
