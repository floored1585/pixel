require_relative 'rspec'

describe Fan do

  json_keys = [ 'device', 'index', 'description', 'last_updated',
                'status', 'vendor_status', 'status_text', 'worker' ]

  data1_base = {
    "device" => "gar-b11u1-dist", "index" => "1.1.1", "description" => "FAN 0 @ 0/0/0",
    "worker" => "test123", "last_updated" => 1427164532, "status" => 1, "vendor_status" => 2,
    "status_text" => "OK" }
  data2_base = {
    "device" => "gar-b11u17-acc-g", "index" => "1004", "description" => "Switch#1,  Fan#1", 
    "worker" => "test123", "last_updated" => 1427164623, "status" => 1, "vendor_status" => 1,
    "status_text" => "OK"}
  data3_base = {
    "device" => "iad1-trn-1", "index" => "1.1", "description" => "PSU 1.1", "worker" => "test123",
    "last_updated" => 1427164801, "status" => 1, "vendor_status" => 1, "status_text" => "OK" }
  imaginary_data = {
    "device" => "test-test-test-1", "index" => "1.1", "description" => "PSU 1.1", "worker" => "test123",
    "last_updated" => 1427164801, "status" => 1, "vendor_status" => 1, "status_text" => "OK" }

  data1_update_ok = {
    "device" => "gar-b11u1-dist",
    "index" => "4.1.1.1",
    "description" => "FAN 0 @ 0/0/0",
    "last_updated" => 1427164532,
    "status" => 1,
    "vendor_status" => 2,
    "status_text" => "OK" }
  data2_update_ok = {
    "device" => "gar-b11u17-acc-g",
    "index" => "1004",
    "description" => "Switch#1,  Fan#1",
    "last_updated" => 1427164623,
    "status" => 1,
    "vendor_status" => 1,
    "status_text" => "OK" }
  data3_update_ok = {
    "device" => "iad1-trn-1",
    "index" => "1.1",
    "description" => "PSU 1.1",
    "last_updated" => 1427164901,
    "status" => 1,
    "vendor_status" => 1,
    "status_text" => "OK" }

  # Constructor
  describe '#new' do

    context 'with good data' do
      it 'should return a Fan object' do
        fan = Fan.new(device: 'gar-test-1', index: 103)
        expect(fan).to be_a Fan
      end
    end

  end


  # fetch
  describe '#fetch' do

    before :each do
      @bad_fan = Fan.fetch('gar-test-1', 'test')
      @good_fan = Fan.fetch('iad1-bdr-1', '1.4.0')
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_fan).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_fan).to be_a Fan
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_fan.to_json)['data'].keys).to eql json_keys
    end


  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Fan.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = Fan.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when freshly created' do

    before(:each) do
      @fan = Fan.new(device: 'gar-test-1', index: '103')
    end


    # device
    describe '#device' do
      specify { expect(@fan.device).to eql 'gar-test-1' }
    end

    # index
    describe '#index' do
      specify { expect(@fan.index).to eql '103' }
    end

    # description
    describe '#description' do
      specify { expect(@fan.description).to eql '' }
    end

    # status_text
    describe '#status_text' do
      specify { expect(@fan.status_text).to eql nil }
    end

    # update
    describe '#update' do
      obj = Fan.new(device: 'gar-test-1', index: '103').update(data1_update_ok, worker: 'test')
      specify { expect(obj).to be_a Fan }
      specify { expect(obj.description).to eql "FAN 0 @ 0/0/0" }
      specify { expect(obj.last_updated).to be > Time.now.to_i - 1000 }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@fan.last_updated).to eql 0 }
    end

  end


  context 'when populated' do

    before(:each) do
      @fan1 = Fan.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
      @fan2 = Fan.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
      @fan3 = Fan.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
    end

    # device
    describe '#device' do
      specify { expect(@fan1.device).to eql 'gar-b11u1-dist' }
      specify { expect(@fan2.device).to eql 'gar-k11u1-dist' }
      specify { expect(@fan3.device).to eql 'gar-k11u1-dist' }
    end

    # index
    describe '#index' do
      specify { expect(@fan1.index).to eql '7.1.0.0' }
      specify { expect(@fan2.index).to eql '1' }
      specify { expect(@fan3.index).to eql '1' }
    end

    # description
    describe '#description' do
      specify { expect(@fan1.description).to eql 'FAN 0 @ 0/0/0' }
      specify { expect(@fan2.description).to eql 'Switch#1,  Fan#1' }
      specify { expect(@fan3.description).to eql 'PSU 1.1' }
    end

    # status_text
    describe '#status_text' do
      specify { expect(@fan1.status_text).to eql 'OK' }
      specify { expect(@fan2.status_text).to eql 'OK' }
      specify { expect(@fan3.status_text).to eql 'OK' }
    end

    # update
    describe '#update' do
      specify { expect(@fan1.update(data1_update_ok, worker: 'test')).to be_a Fan }
      specify { expect(@fan2.update(data2_update_ok, worker: 'test')).to be_a Fan }
      specify { expect(@fan3.update(data3_update_ok, worker: 'test')).to be_a Fan }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@fan1.last_updated).to eql data1_base['last_updated'].to_i }
      specify { expect(@fan2.last_updated).to eql data2_base['last_updated'].to_i }
      specify { expect(@fan3.last_updated).to eql data3_base['last_updated'].to_i }
    end

  end


  # save
  describe '#save' do

    before :each do
      # Insert our bare bones device, just name and IP
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should not exist before saving' do
      fan = Fan.fetch('test-v11u1-acc-y', '1004')
      expect(fan).to eql nil
    end

    it 'should fail if empty' do
      fan = Fan.new(device: 'test-v11u1-acc-y', index: '1004')
      expect(fan.save(DB)).to eql nil
    end

    it 'should fail if device does not exist' do
      fan = Fan.new(device: 'test-test-test-y', index: '1004').populate(imaginary_data)
      expect(fan.save(DB)).to eql nil
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).fans['1004'].save(DB)
      fan = Fan.fetch('test-v11u1-acc-y', '1004')
      expect(fan).to be_a Fan
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).fans['1004'].save(DB)
      JSON.load(DEV2_JSON).fans['1004'].save(DB)
      fan = Fan.fetch('test-v11u1-acc-y', '1004')
      expect(fan).to be_a Fan
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).fans['1004'].save(DB)
      fan = Fan.fetch('test-v11u1-acc-y', '1004')
      expect(fan.to_json).to eql JSON.load(DEV2_JSON).fans['1004'].to_json
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
      JSON.load(DEV2_JSON).fans['1004'].save(DB)
      object = Fan.new(device: 'test-v11u1-acc-y', index: '1004')
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = Fan.new(device: 'test-v11u1-acc-y', index: '1004')
      expect(object.delete(DB)).to eql 0
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @fan = Fan.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@fan.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @fan.to_json
        expect(JSON.load(json)).to be_a Fan
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @fan1 = Fan.fetch('gar-b11u1-dist', '4.1.1.1')
        @fan2 = Fan.fetch('iad1-bdr-1', '4.1.4.0')
        @fan3 = Fan.fetch('gar-k11u1-dist', '1')
        @fan4 = Fan.fetch('iad1-trn-1', '2.1')
      end


      it 'should serialize and deserialize properly' do
        json1 = @fan1.to_json
        json2 = @fan2.to_json
        json3 = @fan3.to_json
        json4 = @fan4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end


end
