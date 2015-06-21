require_relative '../rspec'

describe ComponentEvent do

  device = 'gar-bdr-1'
  hw_type = 'CPU'
  index = '1'
  time = Time.now.to_i

  event = ComponentEvent.new(
    device: device, hw_type: hw_type, index: index, time: time
  )

  # Constructor
  describe '#new' do

    context 'when properly formatted with data' do
      it 'should return a ComponentEvent object' do
        expect(event).to be_a ComponentEvent
      end
      it 'should have an accurate time' do
        expect(event.time).to eql time
      end
    end

    context 'when properly formatted with data and time' do
      custom_time = 1000
      time_event = ComponentEvent.new(
        device: device, hw_type: hw_type, index: index, time: custom_time
      )
      it 'should return a ComponentEvent object' do
        expect(time_event).to be_a ComponentEvent
      end
      it 'should have an accurate time' do
        expect(time_event.time).to eql custom_time
      end
    end

    context 'when properly formatted without data' do
      it 'should return a ComponentEvent object' do
        expect(event).to be_a ComponentEvent
      end
    end

    context 'when missing time' do
      it 'should raise an ArgumentError' do
        expect{
          event = ComponentEvent.new(device: device, hw_type: hw_type, index: index)
        }.to raise_error ArgumentError
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
      expect(event.index).to eql '1'
    end

    it 'should convert to String' do
      numeric_index_event = ComponentEvent.new(
        device: device, hw_type: hw_type, index: 100, time: time
      )
      expect(numeric_index_event.index).to eql '100'
    end

  end


  # subtype
  describe '#subtype' do

    it 'should be nil without subclass' do
      expect(event.subtype).to eql nil
    end

  end


  # type
  describe '#type' do

    it 'should be accurate' do
      expect(event.type).to eql 'component'
    end

  end


end
