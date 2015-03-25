require_relative '../lib/cpu'
require_relative '../lib/core_ext/object'

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
      @cpu = CPU.new(device: 'gar-test-1', index: 'test')
    end

    it 'should return a CPU object' do
      expect(@cpu.populate(data1_base)).to be_a CPU
      expect(@cpu.populate(data2_base)).to be_a CPU
      expect(@cpu.populate(data3_base)).to be_a CPU
    end

    it 'should fill up the object' do
      expect(JSON.parse(@cpu.populate(data1_base).to_json).keys).to eql json_keys
      expect(JSON.parse(@cpu.populate(data2_base).to_json).keys).to eql json_keys
      expect(JSON.parse(@cpu.populate(data3_base).to_json).keys).to eql json_keys
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
  describe '#to_json' do

    context 'when freshly created' do

      before(:each) do
        @cpu = CPU.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@cpu.to_json).to be_a String
      end

      it 'should return empty' do
        expect(JSON.parse(@cpu.to_json)).to be_empty
      end

    end


    context 'when populated' do

      before(:each) do
        @cpu = CPU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @cpu2 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
        @cpu3 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
      end


      it 'should have all required keys' do
        expect(JSON.parse(@cpu.to_json).keys).to eql json_keys
        expect(JSON.parse(@cpu2.to_json).keys).to eql json_keys
        expect(JSON.parse(@cpu3.to_json).keys).to eql json_keys
      end

    end

  end


end
