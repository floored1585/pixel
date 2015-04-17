require_relative 'rspec'

describe CPU do

  json_keys = [ 'device', 'index', 'util', 'description', 'last_updated', 'worker' ]

  data1_base = { "device" => "irv-i1u1-dist", "index" => "1", "util" => 8.0, "description" => "Linecard(slot 1)", "last_updated" => 1427224290, "worker" => "test" }
  data2_base = { "device" => "gar-b11u1-dist", "index" => "7.2.0.0", "util" => 54.0, "description" => "FPC: EX4300-48T @ 1/*/*", "last_updated" => 1427224144, "worker" => "test" }
  data3_base = { "device" => "aon-cumulus-3", "index" => "768", "util" => 20.0, "description" => "CPU 768", "last_updated" => 1427224306, "worker" => "test" }
  imaginary_data = { "device" => "test-test", "index" => "768", "util" => 20.0, "description" => "CPU 768", "last_updated" => 1427224306, "worker" => "test" }

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


  # fetch
  describe '#fetch' do

    before :each do
      @bad_cpu = CPU.fetch('gar-test-1', 'test')
      @good_cpu = CPU.fetch('iad1-trn-1', '2')
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_cpu).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_cpu).to be_a CPU
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_cpu.to_json)['data'].keys).to eql json_keys
    end


  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = CPU.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys).to eql json_keys
    end
  end


  context 'when freshly created' do

    before(:each) do
      @cpu = CPU.new(device: 'gar-test-1', index: '103')
    end


    # index
    describe '#index' do
      specify { expect(@cpu.index).to eql '103' }
    end

    # update
    describe '#update' do
      specify { expect(@cpu.update(data1_update_ok, worker: 'test')).to be_a CPU }
    end
    
    # last_updated
    describe '#last_updated' do
      specify { expect(@cpu.last_updated).to eql 0 }
    end

  end


  context 'when populated' do

    before(:each) do
      @cpu1 = CPU.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
      @cpu2 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
      @cpu3 = CPU.new(device: 'gar-k11u1-dist', index: '1').populate(data3_base)
    end


    # index
    describe '#index' do
      specify { expect(@cpu1.index).to eql '7.1.0.0' }
      specify { expect(@cpu2.index).to eql '1' }
      specify { expect(@cpu3.index).to eql '1' }
    end

    # update
    describe '#update' do
      specify { expect(@cpu1.update(data1_update_ok, worker: 'test')).to be_a CPU }
      specify { expect(@cpu2.update(data2_update_ok, worker: 'test')).to be_a CPU }
      specify { expect(@cpu3.update(data3_update_ok, worker: 'test')).to be_a CPU }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@cpu1.last_updated).to eql data1_base['last_updated'].to_i }
      specify { expect(@cpu2.last_updated).to eql data2_base['last_updated'].to_i }
      specify { expect(@cpu3.last_updated).to eql data3_base['last_updated'].to_i }
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
      cpu = CPU.fetch('test-v11u1-acc-y', '1')
      expect(cpu).to eql nil
    end

    it 'should fail if empty' do
      cpu = CPU.new(device: 'test-v11u1-acc-y', index: '1')
      expect{cpu.save(DB)}.to raise_error Sequel::NotNullConstraintViolation
    end

    it 'should fail if device does not exist' do
      cpu = CPU.new(device: 'test-test-acc-y', index: '1').populate(imaginary_data)
      expect{cpu.save(DB)}.to raise_error Sequel::ForeignKeyConstraintViolation
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).cpus['1'].save(DB)
      cpu = CPU.fetch('test-v11u1-acc-y', '1')
      expect(cpu).to be_a CPU
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).cpus['1'].save(DB)
      JSON.load(DEV2_JSON).cpus['1'].save(DB)
      cpu = CPU.fetch('test-v11u1-acc-y', '1')
      expect(cpu).to be_a CPU
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).cpus['1'].save(DB)
      cpu = CPU.fetch('test-v11u1-acc-y', '1')
      expect(cpu.to_json).to eql JSON.load(DEV2_JSON).cpus['1'].to_json
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
      JSON.load(DEV2_JSON).cpus['1'].save(DB)
      object = CPU.new(device: 'test-v11u1-acc-y', index: '1')
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = CPU.new(device: 'test-v11u1-acc-y', index: '1')
      expect(object.delete(DB)).to eql 0
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
        expect(JSON.load(json)).to be_a CPU
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @cpu1 = CPU.fetch('gar-b11u1-dist', '7.1.0.0')
        @cpu2 = CPU.fetch('aon-cumulus-2', '768')
        @cpu3 = CPU.fetch('gar-k11u1-dist', '1')
        @cpu4 = CPU.fetch('iad1-trn-1', '2')
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
