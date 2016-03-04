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

describe ComponentStatusEvent do

  device = 'gar-bdr-1'
  hw_type = 'CPU'
  index = '1'
  old = 'Down'
  new = 'Up'
  time = Time.now.to_i

  event = ComponentStatusEvent.new(
    device: device, hw_type: hw_type, index: index, old: old, new: new
  )

  # Constructor
  describe '#new' do

    context 'when properly formatted' do
      it 'should return a ComponentStatusEvent object' do
        expect(event).to be_a ComponentStatusEvent
      end
      it 'should have an accurate time' do
        expect(event.time).to eql time
      end
    end

    context 'when properly formatted with time' do
      custom_time = 1000
      time_event = ComponentStatusEvent.new(
        device: 'gar-bdr-1', hw_type: 'CPU', index: '1',
        old: 'test', new: 'test_new', time: custom_time
      )
      it 'should return a ComponentStatusEvent object' do
        expect(time_event).to be_a ComponentStatusEvent
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
      expect(event.subtype).to eql 'ComponentStatusEvent'
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


end
