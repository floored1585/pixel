require_relative 'rspec'

describe PSU do

  json_keys = [ 'device', 'index', 'description', 'last_updated',
                'status', 'vendor_status', 'status_text', 'worker' ]

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
    end

  end


  # fetch
  describe '#fetch' do

    before :each do
      @bad_psu = PSU.fetch('gar-test-1', 'test')
      @good_psu = PSU.fetch('iad1-trn-1', '1.1')
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_psu).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_psu).to be_a PSU
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_psu.to_json)['data'].keys).to eql json_keys
    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = PSU.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys).to eql json_keys
    end
  end


  context 'when freshly created' do

    before(:each) do
      @psu = PSU.new(device: 'gar-test-1', index: '103')
    end


    # index
    describe '#index' do
      specify { expect(@psu.index).to eql '103' }
    end

    # update
    describe '#update' do
      specify { expect(@psu.update(data1_update_ok, worker: 'test')).to be_a PSU }
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


    # index
    describe '#index' do
      specify { expect(@psu1.index).to eql '7.1.0.0' }
      specify { expect(@psu2.index).to eql '1' }
      specify { expect(@psu3.index).to eql '1' }
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
      psu = PSU.fetch('test-v11u1-acc-y', '1003')
      expect(psu).to eql nil
    end

    it 'should fail if empty' do
      psu = PSU.new(device: 'test-v11u1-acc-y', index: '1003')
      expect{psu.save(DB)}.to raise_error Sequel::NotNullConstraintViolation
    end

    it 'should fail if device does not exist' do
      psu = PSU.new(device: 'test-test-y', index: '1003').populate(imaginary_data)
      expect{psu.save(DB)}.to raise_error Sequel::ForeignKeyConstraintViolation
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      psu = PSU.fetch('test-v11u1-acc-y', '1003')
      expect(psu).to be_a PSU
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      psu = PSU.fetch('test-v11u1-acc-y', '1003')
      expect(psu).to be_a PSU
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).psus['1003'].save(DB)
      psu = PSU.fetch('test-v11u1-acc-y', '1003')
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
        @psu1 = PSU.fetch('gar-b11u1-dist', '2.1.1.0')
        @psu2 = PSU.fetch('gar-b11u17-acc-g', '1003')
        @psu3 = PSU.fetch('gar-bdr-1', '2.1.0.0')
        @psu4 = PSU.fetch('iad1-trn-1', '1.1')
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
