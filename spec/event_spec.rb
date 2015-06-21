require_relative 'rspec'

describe Event do


  # Constructor
  describe '#new' do

    context 'with no arguments' do
      it 'should return an Event object' do
        event = Event.new
        expect(event).to be_a Event
      end
      it 'should have an accurate time' do
        time = Time.now.to_i
        event = Event.new
        expect(event.time).to eql time
      end
    end

    context 'with a manual integer time' do
      it 'should return an Event object' do
        time = 1000
        event = Event.new(time)
        expect(event).to be_a Event
      end
      it 'should have an accurate time' do
        time = 1000
        event = Event.new(time)
        expect(event.time).to eql time
      end
    end

    context 'with a manual string time' do
      it 'should return an Event object' do
        time = '1000'
        event = Event.new(time)
        expect(event).to be_a Event
      end
      it 'should have an accurate time' do
        time = '1000'
        event = Event.new(time)
        expect(event.time).to eql 1000
      end
    end

    context 'with a manual invalid time' do
      it 'should raise TypeError' do
        expect{Event.new('abcd')}.to raise_error TypeError
      end
    end

  end


  # time
  describe '#time' do
    event = Event.new

    it 'should be an Integer' do
      expect(event.time).to be_a Integer
    end

  end


  # id
  describe '#id' do
    event = Event.new
    pp event.id

    it 'should be a String' do
      expect(event.id).to be_a String
    end

    it 'should be a uuid' do
      expect(event.id).to match /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/
    end

  end


end
