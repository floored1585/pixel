require_relative '../lib/cpu'

describe CPU do

  json_keys = [ 'device', 'index', 'util', 'description', 'last_updated' ]

  data1_base = { "device" => "irv-i1u1-dist", "index" => "1", "util" => 8.0, "description" => "Linecard(slot 1)", "last_updated" => 1427224290 }
  data2_base = { "device" => "gar-b11u1-dist", "index" => "7.2.0.0", "util" => 54.0, "description" => "FPC: EX4300-48T @ 1/*/*", "last_updated" => 1427224144 }
  data3_base = { "device" => "aon-cumulus-3", "index" => "768", "util" => 20.0, "description" => "CPU 768", "last_updated" => 1427224306 }

  data1_update_ok = {
    "device" => "irv-i1u1-dist",
    "index" => "1",
    "util" => 10.0,
    "description" => "Linecard(slot 1)",
    "last_updated" => 1427224490 }
  data2_update_ok = {
    "device" => "gar-b11u1-dist",
    "index" => "7.2.0.0",
    "util" => 54.2,
    "description" => "FPC: EX4300-48T @ 1/*/*",
    "last_updated" => 1427224344 }
  data3_update_ok = {
    "device" => "aon-cumulus-3",
    "index" => "768",
    "util" => 23.0,
    "description" => "CPU 768",
    "last_updated" => 1427224906 }

  # Constructor
  describe '#new' do

    context 'with good data' do
      it 'should return a CPU object' do
        cpu = CPU.new(device: 'gar-test-1', index: 103)
        expect(cpu).to be_a CPU
      end
    end

  end


  # populate
  describe '#populate' do

    before :each do
      @bad_cpu = CPU.new(device: 'gar-test-1', index: 'test')
      @good_cpu = CPU.new(device: 'iad1-trn-1', index: '2')
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_cpu.populate).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_cpu.populate).to be_a CPU
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_cpu.populate(data1_base).to_json)['data'].keys).to eql json_keys
    end


  end


  # update
  describe '#update' do

    context 'when freshly created' do

      before(:each) do
        @cpu = CPU.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a CPU object' do
        expect(@cpu.update(data1_update_ok)).to be_a CPU
      end

    end


    context 'when populated' do

      before(:each) do
        @cpu = CPU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @cpu2 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
        @cpu3 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
      end


      it 'should return a CPU object' do
        expect(@cpu.update(data1_update_ok)).to be_a CPU
        expect(@cpu2.update(data2_update_ok)).to be_a CPU
        expect(@cpu3.update(data3_update_ok)).to be_a CPU
      end

    end

  end

  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @cpu = CPU.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@cpu.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @cpu.to_json
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @cpu1 = CPU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate
        @cpu2 = CPU.new(device: 'aon-cumulus-2', index: '768').populate
        @cpu3 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate
        @cpu4 = CPU.new(device: 'iad1-trn-1', index: '2').populate
      end


      it 'should serialize and deserialize properly' do
        json1 = @cpu1.to_json
        json2 = @cpu2.to_json
        json3 = @cpu3.to_json
        json4 = @cpu4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end


end
