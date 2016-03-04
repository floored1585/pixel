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

# mac.rb
#
require 'json'

class Mac


  def initialize(device:, if_index:, mac:, vlan_id:, last_updated:)

    # If the incoming data doesn't look like it should, raise an exception.
    unless if_index.to_s =~ /^[0-9]+$/
      raise TypeError.new("if_index (#{if_index}) must look like an Integer!") 
    end
    unless mac.to_s.downcase =~ /^([0-9a-f]{2}[:-]){5}([0-9a-f]{2})$/
      raise TypeError.new("mac (#{mac}) must look like a MAC address!") 
    end
    unless vlan_id.to_s =~ /^[0-9]+$/
      raise TypeError.new("vlan_id (#{vlan_id}) must look like an Integer!") 
    end
    unless last_updated.to_s =~ /^[0-9]+$/
      raise TypeError.new("last_updated (#{last_updated}) must look like an Integer!") 
    end

    # required
    @device = device
    @if_index = if_index.to_i
    @mac = mac.to_s.downcase
    @vlan_id = vlan_id.to_i
    @last_updated = last_updated.to_i

  end


  def to_json
    { "device" => @device,
      "if_index" => @if_index,
      "mac" => @mac,
      "vlan_id" => @vlan_id,
      "last_updated" => @last_updated,
    }.to_json
  end


end
