require_relative '../rspec'

describe Memory do

  json_keys = [ 'device', 'index', 'util', 'description', 'last_updated', 'worker' ].sort

  data1_base = {
    "device" => "irv-i1u1-dist", "index" => "1", "util" => 8, "worker" => "test123",
    "description" => "Linecard(slot 1)", "last_updated" => 1427224290 }
  data2_base = {
    "device" => "gar-b11u1-dist", "index" => "7.2.0.0", "util" => 54, "worker" => "test123",
    "description" => "FPC: EX4300-48T @ 1/*/*", "last_updated" => 1427224144 }
  data3_base = {
    "device" => "aon-cumulus-3", "index" => "768", "util" => 20, "description" => "Memory 768", 
    "worker" => "test123", "last_updated" => 1427224306 }
  imaginary_data = {
    "device" => "test-test-3", "index" => "768", "util" => 20, "description" => "Memory 768", 
    "worker" => "test123", "last_updated" => 1427224306 }

  data1_update_ok = {
    "device" => "irv-i1u1-dist",
    "index" => "1",
    "util" => 10,
    "description" => "Linecard(slot 1)",
    "last_updated" => 1427224490 }
  data2_update_ok = {
    "device" => "gar-b11u1-dist",
    "index" => "7.2.0.0",
    "util" => 54,
    "description" => "FPC: EX4300-48T @ 1/*/*",
    "last_updated" => 1427224344 }
  data3_update_ok = {
    "device" => "aon-cumulus-3",
    "index" => "768",
    "util" => 23,
    "description" => "Memory 768",
    "last_updated" => 1427224906 }

  # Constructor
  describe '#new' do

    context 'with good data' do

      it 'should return a Memory object' do
        memory = Memory.new(device: 'gar-test-1', index: 103)
        expect(memory).to be_a Memory
      end

      it 'should have hw_type Memory' do
        expect(Memory.new(device: 'gar-test-1', index: 103).hw_type).to eql 'Memory'
      end

    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Memory.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys.sort).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = Memory.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when freshly created' do

    before(:each) do
      @memory = Memory.new(device: 'gar-test-1', index: '103')
    end


    # device
    describe '#device' do
      specify { expect(@memory.device).to eql 'gar-test-1' }
    end

    # index
    describe '#index' do
      specify { expect(@memory.index).to eql '103' }
    end

    # description
    describe '#description' do
      specify { expect(@memory.description).to eql '' }
    end

    # util
    describe '#util' do
      specify { expect(@memory.util).to eql 0 }
    end

    # update
    describe '#update' do
      obj = Memory.new(device: 'gar-test-1', index: '103').update(data1_update_ok, worker: 'test')
      specify { expect(obj).to be_a Memory }
      specify { expect(obj.description).to eql "Linecard(slot 1)" }
      specify { expect(obj.util).to eql 10 }
      specify { expect(obj.last_updated).to be > Time.now.to_i - 1000 }
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


    # device
    describe '#device' do
      specify { expect(@memory1.device).to eql 'gar-b11u1-dist' }
      specify { expect(@memory2.device).to eql 'gar-k11u1-dist' }
      specify { expect(@memory3.device).to eql 'gar-k11u1-dist' }
    end

    # index
    describe '#index' do
      specify { expect(@memory1.index).to eql '7.1.0.0' }
      specify { expect(@memory2.index).to eql '1' }
      specify { expect(@memory3.index).to eql '1' }
    end

    # description
    describe '#description' do
      specify { expect(@memory1.description).to eql 'Linecard(slot 1)' }
      specify { expect(@memory2.description).to eql 'FPC: EX4300-48T @ 1/*/*' }
      specify { expect(@memory3.description).to eql 'Memory 768' }
    end

    # util
    describe '#util' do
      specify { expect(@memory1.util).to eql 8 }
      specify { expect(@memory2.util).to eql 54 }
      specify { expect(@memory3.util).to eql 20 }
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
      mem = Memory.fetch(device: 'test-v11u1-acc-y', index: '1', hw_types: ['Memory']).first
      expect(mem).to eql nil
    end

    it 'should fail if empty' do
      memory = Memory.new(device: 'test-v11u1-acc-y', index: '1')
      expect(memory.save(DB)).to eql nil
    end

    it 'should fail if device does not exist' do
      memory = Memory.new(device: 'test-test-acc-y', index: '1').populate(imaginary_data)
      expect(memory.save(DB)).to eql nil
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).memory['1'].save(DB)
      mem = Memory.fetch(device: 'test-v11u1-acc-y', index: '1', hw_types: ['Memory']).first
      expect(mem).to be_a Memory
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).memory['1'].save(DB)
      JSON.load(DEV2_JSON).memory['1'].save(DB)
      mem = Memory.fetch(device: 'test-v11u1-acc-y', index: '1', hw_types: ['Memory']).first
      expect(mem).to be_a Memory
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).memory['1'].save(DB)
      mem = Memory.fetch(device: 'test-v11u1-acc-y', index: '1', hw_types: ['Memory']).first
      expect(mem.to_json).to eql JSON.load(DEV2_JSON).memory['1'].to_json
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
      JSON.load(DEV2_JSON).memory['1'].save(DB)
      object = Memory.new(device: 'test-v11u1-acc-y', index: '1')
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = Memory.new(device: 'test-v11u1-acc-y', index: '1')
      expect(object.delete(DB)).to eql 0
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
        @memory1 = Memory.fetch(device: 'gar-b11u1-dist', index: '7.2.0.0', hw_types: ['Memory']).first
        @memory2 = Memory.fetch(device: 'aon-cumulus-2', index: '0', hw_types: ['Memory']).first
        @memory3 = Memory.fetch(device: 'gar-k11u1-dist', index: '1', hw_types: ['Memory']).first
        @memory4 = Memory.fetch(device: 'iad1-trn-1', index: '2', hw_types: ['Memory']).first
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
