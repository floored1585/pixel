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

require_relative '../../rspec'

describe DescriptionEvent do

  device = 'gar-bdr-1'
  hw_type = 'CPU'
  index = '1'
  old = 'old_desc'
  new = 'new_desc'
  time = Time.now.to_i

  event = DescriptionEvent.new(
    device: device, hw_type: hw_type, index: index, old: old, new: new
  )

  # Constructor
  describe '#new' do

    context 'when properly formatted' do
      it 'should return a DescriptionEvent object' do
        expect(event).to be_a DescriptionEvent
      end
      it 'should have an accurate time' do
        expect(event.time).to eql time
      end
    end

    context 'when properly formatted with time' do
      custom_time = 1000
      time_event = DescriptionEvent.new(
        device: 'gar-bdr-1', hw_type: 'CPU', index: '1', old: 'old_desc', new: 'new_desc',
        time: custom_time
      )
      it 'should return a DescriptionEvent object' do
        expect(time_event).to be_a DescriptionEvent
      end
      it 'should have an accurate time' do
        expect(time_event.time).to eql custom_time
      end
    end

  end


  # device
  describe '#device' do

    it 'should be what was passed in' do
      expect(event.device).to eql device
    end

  end


  # hw_type
  describe '#hw_type' do

    it 'should be what was passed in' do
      expect(event.hw_type).to eql hw_type
    end

  end


  # index
  describe '#index' do

    it 'should be what was passed in' do
      expect(event.index).to eql index
    end

  end


  # subtype
  describe '#subtype' do

    it 'should be correct' do
      expect(event.subtype).to eql 'DescriptionEvent'
    end

  end


  # old
  describe '#old' do

    it 'should be correct' do
      expect(event.old).to eql old
    end

  end


  # new
  describe '#new' do

    it 'should be correct' do
      expect(event.new).to eql new
    end

  end


  # functional tests
  context 'functional tests' do

    int = JSON.load(INTERFACE_1)
    int_data = JSON.parse(INTERFACE_1)["data"]
    int_data["description"] = "TEST CHANGE DESCRIPTION"
    int_data["high_speed"] = int_data["speed"] / 1000000
    int_updated = int.dup.update(int_data, worker: 'test')
    func_event = int_updated.events.first

    it 'should not be present before a change' do
      expect(int.events).to be_empty
    end

    it 'should be present when description changes' do
      expect(func_event).to be_a DescriptionEvent
    end

    it 'should have the correct old description' do
      expect(func_event.old).to eql int.description
    end

    it 'should have the correct new description' do
      expect(func_event.new).to eql int_updated.description
    end

    it 'should have the correct time' do
      expect(func_event.time).to eql int_updated.last_updated
    end

  end

  context 'saving' do

    before :each do
      JSON.load(DEVTEST_JSON).save(DB)
      int_save = JSON.load(INTERFACE_5)
      int_save_data = JSON.parse(INTERFACE_5)["data"]
      int_save_data["description"] = ""
      int_save_data["high_speed"] = int_save_data["speed"] / 1000000
      int_save_updated = int_save.dup.update(int_save_data, worker: 'test')
      int_save_updated.save(DB)
    end

    after :each do
      DB[:device].where(device: 'test-v11u3-acc-y').delete
    end

    it 'should be saved' do
      saved_event = ComponentEvent.fetch(
        device: 'test-v11u3-acc-y', hw_type: 'Interface',
        index: '10119', types: [ 'DescriptionEvent' ]
      ).first
      expect(saved_event).to be_a DescriptionEvent
    end

  end

end
