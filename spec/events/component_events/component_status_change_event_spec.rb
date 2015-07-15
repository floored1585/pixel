require_relative '../../rspec'

describe ComponentStatusChangeEvent do

  device = 'gar-bdr-1'
  hw_type = 'CPU'
  index = '1'
  status = 'down'
  time = Time.now.to_i

  event = ComponentStatusChangeEvent.new(
    device: device, hw_type: hw_type, index: index, status: status
  )

  # Constructor
  describe '#new' do

    context 'when properly formatted' do
      it 'should return a ComponentStatusChangeEvent object' do
        expect(event).to be_a ComponentStatusChangeEvent
      end
      it 'should have an accurate time' do
        expect(event.time).to eql time
      end
    end

    context 'when properly formatted with time' do
      custom_time = 1000
      time_event = ComponentStatusChangeEvent.new(
        device: 'gar-bdr-1', hw_type: 'CPU', index: '1',
        status: 'test_status', time: custom_time
      )
      it 'should return a ComponentStatusChangeEvent object' do
        expect(time_event).to be_a ComponentStatusChangeEvent
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
      expect(event.subtype).to eql 'ComponentStatusChangeEvent'
    end

  end


  # status
  describe '#status' do

    it 'should be correct' do
      expect(event.status).to eql status
    end

  end


end
