require_relative '../rspec'

describe PSU do

  json_keys = [ 'device', 'index', 'description', 'last_updated',
                'status', 'vendor_status', 'status_text', 'worker' ].sort

  data1_base = {
    "device" => "gar-b11u1-dist", "index" => "4.1.1.1", "description" => "PSU 0 @ 0/0/0",
    "worker" => "test123", "last_updated" => 1427164532, "status" => 1, "vendor_status" => 2,
    "status_text" => "OK" }
  data2_base = {
    "device" => "gar-b11u17-acc-g", "index" => "1004", "description" => "Switch#1,  PSU#1",
    "worker" => "test123", "last_updated" => 1427164623, "status" => 1, "vendor_status" => 1,
    "status_text" => "OK" }
  data3_base = {
    "device" => "iad1-trn-1", "index" => "1.1", "description" => "PSU 1.1", "worker" => "test123",
    "last_updated" => 1427164801, "status" => 1, "vendor_status" => 1, "status_text" => "OK" }
  imaginary_data = {
    "device" => "test-test-1", "index" => "1.1", "description" => "PSU 1.1", "worker" => "test123",
    "last_updated" => 1427164801, "status" => 1, "vendor_status" => 1, "status_text" => "OK" }

  data1_update_ok = {
    "device" => "gar-b11u1-dist",
    "index" => "4.1.1.1",
    "description" => "PSU 0 @ 0/0/0",
    "last_updated" => 1427164532,
    "status" => 1,
    "vendor_status" => 2,
    "status_text" => "OK" }
  data2_update_ok = {
    "device" => "gar-b11u17-acc-g",
    "index" => "1004",
    "description" => "Switch#1,  PSU#1",
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

      it 'should return a PSU object' do
        psu = PSU.new(device: 'gar-test-1', index: 103)
        expect(psu).to be_a PSU
      end

      it 'should have hw_type PSU' do
        expect(PSU.new(device: 'gar-test-1', index: 103).hw_type).to eql 'PSU'
      end

    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = PSU.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys.sort).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = PSU.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when freshly created' do

    before(:each) do
      @psu = PSU.new(device: 'gar-test-1', index: '103')
    end


    # device
    describe '#device' do
      specify { expect(@psu.device).to eql 'gar-test-1' }
    end

    # index
    describe '#index' do
      specify { expect(@psu.index).to eql '103' }
    end

    # description
    describe '#description' do
      specify { expect(@psu.description).to eql '' }
    end

    # status_text
    describe '#status_text' do
      specify { expect(@psu.status_text).to eql nil }
    end

    # update
    describe '#update' do
      obj = PSU.new(device: 'gar-test-1', index: '103').update(data1_update_ok, worker: 'test')
      specify { expect(obj).to be_a PSU }
      specify { expect(obj.description).to eql "PSU 0 @ 0/0/0" }
      specify { expect(obj.last_updated).to be > Time.now.to_i - 1000 }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@psu.last_updated).to eql 0 }
    end

  end


  context 'when populated' do

    before(:each) do
      @psu1 = PSU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
      @psu2 = PSU.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
      @psu3 = PSU.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
    end


    # device
    describe '#device' do
      specify { expect(@psu1.device).to eql 'gar-b11u1-dist' }
      specify { expect(@psu2.device).to eql 'gar-k11u1-dist' }
      specify { expect(@psu3.device).to eql 'gar-k11u1-dist' }
    end

    # index
    describe '#index' do
      specify { expect(@psu1.index).to eql '7.1.0.0' }
      specify { expect(@psu2.index).to eql '1' }
      specify { expect(@psu3.index).to eql '1' }
    end

    # description
    describe '#description' do
      specify { expect(@psu1.description).to eql 'PSU 0 @ 0/0/0' }
      specify { expect(@psu2.description).to eql 'Switch#1,  PSU#1' }
      specify { expect(@psu3.description).to eql 'PSU 1.1' }
    end

    # status_text
    describe '#status_text' do
      specify { expect(@psu1.status_text).to eql 'OK' }
      specify { expect(@psu2.status_text).to eql 'OK' }
      specify { expect(@psu3.status_text).to eql 'OK' }
    end

    # update
    describe '#update' do
      specify { expect(@psu1.update(data1_update_ok, worker: 'test')).to be_a PSU }
      specify { expect(@psu2.update(data2_update_ok, worker: 'test')).to be_a PSU }
      specify { expect(@psu3.update(data3_update_ok, worker: 'test')).to be_a PSU }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@psu1.last_updated).to eql data1_base['last_updated'] }
      specify { expect(@psu2.last_updated).to eql data2_base['last_updated'] }
      specify { expect(@psu3.last_updated).to eql data3_base['last_updated'] }
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
      psu = PSU.fetch(device: 'test-v11u1-acc-y', index: '1003', hw_types: ['PSU']).first
      expect(psu).to eql nil
    end

    it 'should fail if empty' do
      psu = PSU.new(device: 'test-v11u1-acc-y', index: '1003')
      expect(psu.save(DB)).to eql nil
    end

    it 'should fail if device does not exist' do
      psu = PSU.new(device: 'test-test-y', index: '1003').populate(imaginary_data)
      expect(psu.save(DB)).to eql nil
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      psu = PSU.fetch(device: 'test-v11u1-acc-y', index: '1003', hw_types: ['PSU']).first
      expect(psu).to be_a PSU
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      psu = PSU.fetch(device: 'test-v11u1-acc-y', index: '1003', hw_types: ['PSU']).first
      expect(psu).to be_a PSU
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      psu = PSU.fetch(device: 'test-v11u1-acc-y', index: '1003', hw_types: ['PSU']).first
      expect(psu.to_json).to eql JSON.load(DEV2_JSON).psus['1003'].to_json
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
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      object = PSU.new(device: 'test-v11u1-acc-y', index: '1003')
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = PSU.new(device: 'test-v11u1-acc-y', index: '1003')
      expect(object.delete(DB)).to eql 0
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @psu = PSU.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@psu.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @psu.to_json
        expect(JSON.load(json)).to be_a PSU
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @psu1 = PSU.fetch(device: 'gar-b11u1-dist', index: '2.1.1.0', hw_types: ['PSU']).first
        @psu2 = PSU.fetch(device: 'gar-b11u17-acc-g', index: '1003', hw_types: ['PSU']).first
        @psu3 = PSU.fetch(device: 'gar-bdr-1', index: '2.1.0.0', hw_types: ['PSU']).first
        @psu4 = PSU.fetch(device: 'iad1-trn-1', index: '1.1', hw_types: ['PSU']).first
      end


      it 'should serialize and deserialize properly' do
        json1 = @psu1.to_json
        json2 = @psu2.to_json
        json3 = @psu3.to_json
        json4 = @psu4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end


end
