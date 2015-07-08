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


  # component_id
  describe '#component_id' do

    #TODO: Fill in

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


  # save
  describe '#save' do

    before :each do
      # Insert our bare bones device and component
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
      DB[:component].insert(
        :hw_type => 'test-v11u1-acc-y',
        :device => 'test-v11u1-acc-y',
        :index => '1',
        :last_updated => '12345678',
        :description => 'CPU 1',
        :worker => 'rspec',
      )
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should not exist before saving' do
      event = Device.fetch('test-v11u1-acc-y')
      expect(event).to eql nil
    end

    it 'should fail if empty' do
      event = ComponentEvent.new(device: 'test-v11u1-acc-y', index: '1')
      expect(event.save(DB)).to eql nil
    end

    it 'should fail if device does not exist' do
      event = ComponentEvent.new(device: 'test-test-acc-y', index: '1').populate(imaginary_data)
      expect(event.save(DB)).to eql nil
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).event['1'].save(DB)
      event = ComponentEvent.fetch('test-v11u1-acc-y', '1')
      expect(event).to be_a ComponentEvent
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).event['1'].save(DB)
      JSON.load(DEV2_JSON).event['1'].save(DB)
      event = ComponentEvent.fetch('test-v11u1-acc-y', '1')
      expect(event).to be_a ComponentEvent
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).event['1'].save(DB)
      event = ComponentEvent.fetch('test-v11u1-acc-y', '1')
      expect(event.to_json).to eql JSON.load(DEV2_JSON).event['1'].to_json
    end

  end


  # delete
  describe '#delete' do

    before :each do
      # Insert our bare bones device, just name and IP
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should return 1 if it exists' do
      JSON.load(DEV2_JSON).event['1'].save(DB)
      object = ComponentEvent.new(device: 'test-v11u1-acc-y', index: '1')
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = ComponentEvent.new(device: 'test-v11u1-acc-y', index: '1')
      expect(object.delete(DB)).to eql 0
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @event = ComponentEvent.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@event.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @event.to_json
        expect(JSON.load(json)).to be_a ComponentEvent
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @event1 = ComponentEvent.fetch('gar-b11u1-dist', '7.2.0.0')
        @event2 = ComponentEvent.fetch('aon-cumulus-2', '0')
        @event3 = ComponentEvent.fetch('gar-k11u1-dist', '1')
        @event4 = ComponentEvent.fetch('iad1-trn-1', '2')
      end


      it 'should serialize and deserialize properly' do
        json1 = @event1.to_json
        json2 = @event2.to_json
        json3 = @event3.to_json
        json4 = @event4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end


end
