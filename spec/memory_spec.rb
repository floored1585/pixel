require_relative 'rspec'

describe Memory do

  json_keys = [ 'device', 'index', 'util', 'description', 'last_updated', 'worker' ]

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
      @bad_memory = Memory.new(device: 'gar-test-1', index: 'test')
      @good_memory = Memory.new(device: 'iad1-trn-1', index: '2')
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_memory.populate).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_memory.populate).to be_a Memory
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_memory.populate(data1_base).to_json)['data'].keys).to eql json_keys
    end


  end


  context 'when freshly created' do

    before(:each) do
      @memory = Memory.new(device: 'gar-test-1', index: '103')
    end


    # update
    describe '#update' do
      specify { expect(@memory.update(data1_update_ok, worker: 'test')).to be_a Memory }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@memory.last_updated).to eql 0 }
    end

  end


  context 'when populated' do

    before(:each) do
      @memory1 = Memory.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
      @memory2 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
      @memory3 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
    end


    # update
    describe '#update' do
      specify { expect(@memory1.update(data1_update_ok, worker: 'test')).to be_a Memory }
      specify { expect(@memory2.update(data2_update_ok, worker: 'test')).to be_a Memory }
      specify { expect(@memory3.update(data3_update_ok, worker: 'test')).to be_a Memory }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@memory1.last_updated).to eql data1_base['last_updated'].to_i }
      specify { expect(@memory2.last_updated).to eql data2_base['last_updated'].to_i }
      specify { expect(@memory3.last_updated).to eql data3_base['last_updated'].to_i }
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @memory = Memory.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@memory.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @memory.to_json
        expect(JSON.load(json)).to be_a Memory
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @memory1 = Memory.new(device: 'gar-b11u1-dist', index: '7.2.0.0').populate
        @memory2 = Memory.new(device: 'aon-cumulus-2', index: '0').populate
        @memory3 = Memory.new(device: 'gar-k11u1-dist', index: '1').populate
        @memory4 = Memory.new(device: 'iad1-trn-1', index: '2').populate
      end


      it 'should serialize and deserialize properly' do
        json1 = @memory1.to_json
        json2 = @memory2.to_json
        json3 = @memory3.to_json
        json4 = @memory4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end


end
