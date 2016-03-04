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

require_relative '../lib/mac'
require_relative '../lib/core_ext/object'

describe Mac do


  # Constructor
  describe '#new' do

    context 'with good data' do
      it 'should return' do
        mac = Mac.new(
          device: 'gar-test-1',
          if_index: 103,
          mac: '00:11:22:aa:ff:B1',
          vlan_id: 1,
          last_updated: Time.now.to_i )
        expect(mac).to be_a Mac
      end
    end

    context 'with bad if_index' do
      it 'should raise TypeError' do
        expect{ Mac.new(
          device: 'gar-test-1',
          if_index: 103.1,
          mac: '00:11:22:aa:ff:B1',
          vlan_id: 1,
          last_updated: Time.now.to_i )
        }.to raise_error TypeError
      end
    end

    context 'with bad mac' do
      it 'should raise TypeError' do
        expect{ Mac.new(
          device: 'gar-test-1',
          if_index: 103,
          mac: '00:1G:22:aa:ff:B1',
          vlan_id: 1,
          last_updated: Time.now.to_i )
        }.to raise_error TypeError
      end
    end

    context 'with bad vlan_id' do
      it 'should raise TypeError' do
        expect{ Mac.new(
          device: 'gar-test-1',
          if_index: 103,
          mac: '00:11:22:aa:ff:B1',
          vlan_id: -1,
          last_updated: Time.now.to_i )
        }.to raise_error TypeError
      end
    end

    context 'with bad last_updated' do
      it 'should raise TypeError' do
        expect{ Mac.new(
          device: 'gar-test-1',
          if_index: 103,
          mac: '00:11:22:aa:ff:B1',
          vlan_id: 1,
          last_updated: "100.3" )
        }.to raise_error TypeError
      end
    end

  end


  # to_json
  describe '#to_json' do

    before(:each) do
      @mac = Mac.new(
        device: 'gar-test-1',
        if_index: '103',
        mac: '00:11:22:aa:ff:B1',
        vlan_id: '1',
        last_updated: Time.now.to_i )
    end


    it 'should return a string' do
      expect(@mac.to_json).to be_a String
    end

    it 'should have all required keys' do
      keys = %w( device if_index mac vlan_id last_updated )
      expect(JSON.parse(@mac.to_json).keys).to eql keys
    end

    it 'should return an integer for if_index' do
      expect(JSON.parse(@mac.to_json)['if_index']).to be_a Integer
    end
    it 'should return an integer for vlan_id' do
      expect(JSON.parse(@mac.to_json)['vlan_id']).to be_a Integer
    end
    it 'should return an integer for last_updated' do
      expect(JSON.parse(@mac.to_json)['last_updated']).to be_a Integer
    end

  end


end
