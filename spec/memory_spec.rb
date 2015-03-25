require_relative '../lib/memory'
require_relative '../lib/core_ext/object'

describe Memory do

  json_keys = [ 'device', 'index', 'util', 'description', 'last_updated' ]

  data1_base = { "device" => "irv-i1u1-dist", "index" => "1", "util" => 8.0, "description" => "Linecard(slot 1)", "last_updated" => 1427224290 }
  data2_base = { "device" => "gar-b11u1-dist", "index" => "7.2.0.0", "util" => 54.0, "description" => "FPC: EX4300-48T @ 1/*/*", "last_updated" => 1427224144 }
  data3_base = { "device" => "aon-cumulus-3", "index" => "768", "util" => 20.0, "description" => "Memory 768", "last_updated" => 1427224306 }

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
    "description" => "Memory 768",
    "last_updated" => 1427224906 }

  # Constructor
  describe '#new' do

    context 'with good data' do
      it 'should return a Memory object' do
        memory = Memory.new(device: 'gar-test-1', index: 103)
        expect(memory).to be_a Memory
      end
    end

  end


  # populate
  describe '#populate' do

    before :each do
      @memory = Memory.new(device: 'gar-test-1', index: 'test')
    end

    it 'should return a Memory object' do
      expect(@memory.populate(data1_base)).to be_a Memory
      expect(@memory.populate(data2_base)).to be_a Memory
      expect(@memory.populate(data3_base)).to be_a Memory
    end

    it 'should fill up the object' do
      expect(JSON.parse(@memory.populate(data1_base).to_json).keys).to eql json_keys
      expect(JSON.parse(@memory.populate(data2_base).to_json).keys).to eql json_keys
      expect(JSON.parse(@memory.populate(data3_base).to_json).keys).to eql json_keys
    end


  end


  # update
  describe '#update' do

    context 'when freshly created' do

      before(:each) do
        @memory = Memory.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a Memory object' do
        expect(@memory.update(data1_update_ok)).to be_a Memory
      end

    end


    context 'when populated' do

      before(:each) do
        @memory = Memory.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @memory2 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
        @memory3 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
      end


      it 'should return a Memory object' do
        expect(@memory.update(data1_update_ok)).to be_a Memory
        expect(@memory2.update(data2_update_ok)).to be_a Memory
        expect(@memory3.update(data3_update_ok)).to be_a Memory
      end

    end

  end

  # to_json
  describe '#to_json' do

    context 'when freshly created' do

      before(:each) do
        @memory = Memory.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@memory.to_json).to be_a String
      end

      it 'should return empty' do
        expect(JSON.parse(@memory.to_json)).to be_empty
      end

    end


    context 'when populated' do

      before(:each) do
        @memory = Memory.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @memory2 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
        @memory3 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
      end


      it 'should have all required keys' do
        expect(JSON.parse(@memory.to_json).keys).to eql json_keys
        expect(JSON.parse(@memory2.to_json).keys).to eql json_keys
        expect(JSON.parse(@memory3.to_json).keys).to eql json_keys
      end

    end

  end


end
