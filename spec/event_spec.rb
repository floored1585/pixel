require_relative 'rspec'

describe Event do

  time = 1000
  event = Event.new(time: time)

  # Constructor
  describe '#new' do

    context 'with a manual integer time' do
      it 'should have an accurate time' do
        expect(event.time).to eql time
      end
    end

    context 'with a manual string time' do
      it 'should have an accurate time' do
        time_string = '1000'
        time_string_event = Event.new(time: time_string)
        expect(time_string_event.time).to eql 1000
      end
    end

    context 'with an invalid time' do
      it 'should raise TypeError' do
        expect{Event.new(time: 'abcd')}.to raise_error TypeError
      end
    end

    context 'when missing time' do
      it 'should raise an ArgumentError' do
        expect{event = Event.new}.to raise_error ArgumentError
      end
    end

  end


  # time
  describe '#time' do

    it 'should be an Integer' do
      expect(event.time).to be_a Integer
    end

  end


=begin
  # id
  describe '#id' do

    it 'should be a String' do
      expect(event.id).to be_a String
    end

    it 'should be a uuid' do
      expect(event.id).to match /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/
    end

  end
=end


  # type
  describe '#type' do

    it 'should return a nil without subclass' do
      expect(event.type).to eql nil
    end

  end


end
