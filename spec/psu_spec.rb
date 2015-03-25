require_relative '../lib/psu'
require_relative '../lib/core_ext/object'

describe PSU do

  json_keys = [ 'device', 'index', 'description', 'last_updated',
                'status', 'vendor_status', 'status_text' ]

  data1_base = {"device" => "gar-b11u1-dist", "index" => "4.1.1.1", "description" => "PSU 0 @ 0/0/0", "last_updated" => 1427164532, "status" => 1, "vendor_status" => 2, "status_text" => "OK"}
  data2_base = {"device" => "gar-b11u17-acc-g", "index" => "1004", "description" => "Switch#1,  PSU#1", "last_updated" => 1427164623, "status" => 1, "vendor_status" => 1, "status_text" => "OK"}
  data3_base = {"device" => "iad1-trn-1", "index" => "1.1", "description" => "PSU 1.1", "last_updated" => 1427164801, "status" => 1, "vendor_status" => 1, "status_text" => "OK"}

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


  # populate
  describe '#populate' do

    before :each do
      @psu = PSU.new(device: 'gar-test-1', index: 'test')
    end

    it 'should return a PSU object' do
      expect(@psu.populate(data1_base)).to be_a PSU
      expect(@psu.populate(data2_base)).to be_a PSU
      expect(@psu.populate(data3_base)).to be_a PSU
    end

    it 'should fill up the object' do
      expect(JSON.parse(@psu.populate(data1_base).to_json).keys).to eql json_keys
      expect(JSON.parse(@psu.populate(data2_base).to_json).keys).to eql json_keys
      expect(JSON.parse(@psu.populate(data3_base).to_json).keys).to eql json_keys
    end


  end


  # update
  describe '#update' do

    context 'when freshly created' do

      before(:each) do
        @psu = PSU.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a PSU object' do
        expect(@psu.update(data1_update_ok)).to be_a PSU
      end

    end


    context 'when populated' do

      before(:each) do
        @psu = PSU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @psu2 = PSU.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
        @psu3 = PSU.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
      end


      it 'should return a PSU object' do
        expect(@psu.update(data1_update_ok)).to be_a PSU
        expect(@psu2.update(data2_update_ok)).to be_a PSU
        expect(@psu3.update(data3_update_ok)).to be_a PSU
      end

    end

  end

  # to_json
  describe '#to_json' do

    context 'when freshly created' do

      before(:each) do
        @psu = PSU.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@psu.to_json).to be_a String
      end

      it 'should return empty' do
        expect(JSON.parse(@psu.to_json)).to be_empty
      end

    end


    context 'when populated' do

      before(:each) do
        @psu = PSU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @psu2 = PSU.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
        @psu3 = PSU.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
      end


      it 'should have all required keys' do
        expect(JSON.parse(@psu.to_json).keys).to eql json_keys
        expect(JSON.parse(@psu2.to_json).keys).to eql json_keys
        expect(JSON.parse(@psu3.to_json).keys).to eql json_keys
      end

    end

  end


end
