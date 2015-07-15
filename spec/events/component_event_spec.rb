require_relative '../rspec'

describe ComponentEvent do

  device = 'gar-bdr-1'
  hw_type = 'CPU'
  index = '1'
  time = Time.now.to_i
  subtype = 'ComponentEvent'

  event = ComponentEvent.new(
    device: device, hw_type: hw_type, index: index,
    time: time
  )


  # Fetch
  describe '#fetch' do

    before :each do
      # Insert our bare bones device and component
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
      @component_id = DB[:component].insert(
        :hw_type => 'cpu',
        :device => 'test-v11u1-acc-y',
        :index => '1',
        :last_updated => '12345678',
        :description => 'CPU 1',
        :worker => 'rspec',
      )
      # Insert the event we're going to fetch
      @id = DB[:component_event].insert(
        :component_id => @component_id,
        :subtype => 'DescriptionEvent',
        :time => Time.now.to_i,
        :data => '{"old":"bb__iad1-trn-1__g0/1","new":"bb__iad1-trn-1__g0/2"}',
      )
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    context 'when using component_id' do

      it 'should return an array under any condition' do
        expect(ComponentEvent.fetch(comp_id: 0)).to be_an Array
        expect(ComponentEvent.fetch(comp_id: @component_id)).to be_an Array
      end

      it 'should return an empty array for invalid comp_id' do
        expect(ComponentEvent.fetch(comp_id: 0)).to be_empty
      end

      it 'should return an empty array for invalid comp_id' do
        expect(ComponentEvent.fetch(comp_id: 'abcd')).to be_empty
      end

      it 'should fetch a ComponentEvent' do
        expect(ComponentEvent.fetch(comp_id: @component_id).first).to be_a ComponentEvent
      end

      it 'should actually be a DescriptionChangeEvent' do
        expect(ComponentEvent.fetch(comp_id: @component_id).first).to be_a DescriptionEvent
      end

    end



  end


  # Fetch_from_db
  describe '#fetch_from_db' do

    before :each do
      # Insert our bare bones device and component
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
      @component_id = DB[:component].insert(
        :hw_type => 'cpu',
        :device => 'test-v11u1-acc-y',
        :index => '1',
        :last_updated => '12345678',
        :description => 'CPU 1',
        :worker => 'rspec',
      )
      # Insert the event we're going to fetch
      @id = DB[:component_event].insert(
        :component_id => @component_id,
        :subtype => subtype,
        :time => Time.now.to_i,
        :data => '{"old":"bb__iad1-trn-1__g0/1","new":"bb__iad1-trn-1__g0/2"}',
      )
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end



  end


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

  end


  # component_id
  describe '#component_id' do

    #TODO: Fill in

  end


  # set_component_id
  describe '#set_component_id' do

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

    it 'should be what was passed in' do
      expect(event.subtype).to eql subtype
    end

  end


  # save
  describe '#save' do

    before :each do
      # Insert our bare bones device and component
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
      @id = DB[:component].insert(
        :hw_type => 'cpu',
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
      event = ComponentEvent.fetch(device: device, hw_type: hw_type, index: index).first
      expect(event).to eql nil
    end

    it 'should fail if empty' do
      event = ComponentEvent.new(device: 'test-v11u1-acc-y', index: '1', hw_type: 'CPU',
                                 time: Time.now.to_i)
      expect(event.save(db: DB, data: {})).to eql nil
    end

    it 'should fail if device does not exist' do
      event = ComponentEvent.new(device: 'test-test-acc-y', index: '1', hw_type: 'CPU',
                                 time: Time.now.to_i)
      expect(event.save(db: DB, data: {'test'=>'data'})).to eql nil
    end

    it 'should exist after being saved' do
      event = ComponentEvent.new(device: 'test-v11u1-acc-y', index: '1', hw_type: 'CPU',
                                 time: Time.now.to_i)
      event.save(db: DB, data: {'test'=>'data'})
      event1 = ComponentEvent.fetch(device: 'test-v11u1-acc-y', index: '1', hw_type: 'CPU').first
      expect(event1).to be_a ComponentEvent
    end

  end


=begin
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
=end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @event = ComponentEvent.new(comp_id: 123, time: Time.now.to_i)
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

  end

end
