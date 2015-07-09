require_relative 'rspec'

describe Component do

  json_keys = [ 'device', 'index', 'description', 'last_updated', 'worker' ].sort

  data1_base = { "device" => "irv-i1u1-dist", "index" => "1", "description" => "Linecard(slot 1)", "last_updated" => 1427224290, "worker" => "test" }
  data2_base = { "device" => "gar-b11u1-dist", "index" => "7.2.0.0", "description" => "FPC: EX4300-48T @ 1/*/*", "last_updated" => 1427224144, "worker" => "test" }
  data3_base = { "device" => "aon-cumulus-3", "index" => "768", "description" => "Component 768", "last_updated" => 1427224306, "worker" => "test" }
  imaginary_data = { "device" => "test-test", "index" => "768", "description" => "Component 768", "last_updated" => 1427224306, "worker" => "test" }

  data1_update_ok = {
    "device" => "irv-i1u1-dist",
    "index" => "1",
    "description" => "Linecard(slot 1)",
    "last_updated" => 1427224490 }
  data2_update_ok = {
    "device" => "gar-b11u1-dist",
    "index" => "7.2.0.0",
    "description" => "FPC: EX4300-48T @ 1/*/*",
    "last_updated" => 1427224344 }
  data3_update_ok = {
    "device" => "aon-cumulus-3",
    "index" => "768",
    "description" => "Component 768",
    "last_updated" => 1427224906 }

  # Constructor
  describe '#new' do

    context 'with good data' do

      it 'should return a Component object' do
        component = Component.new(device: 'gar-test-1', index: 103, hw_type: 'rspec')
        expect(component).to be_a Component
      end

    end

  end


  # id
  describe '#id' do

    context 'when component exists' do

      it 'should return the right id' do
        id = Component.id(device: 'gar-b11u1-dist', index: '7.2.0.0', hw_type: 'CPU', db: DB)
        expect(id).to be_a Numeric
        expect(id).to be > 0
      end

    end

  end


  # fetch_id
  describe '#fetch_id' do

    context 'when component exists' do

      it 'should return the right id' do
        id = Component.fetch_id(device: 'gar-b11u1-dist', index: '7.2.0.0', hw_type: 'CPU')
        expect(id).to be_a Numeric
        expect(id).to be > 0
      end

    end

  end



  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Component.new(device: 'iad1-bdr-1', index: '1.4.0', hw_type: 'cpu')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys.sort).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = Component.new(device: 'iad1-bdr-1', index: '1.4.0', hw_type: 'cpu')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when freshly created' do

    before(:each) do
      @component = Component.new(device: 'gar-test-1', index: '103', hw_type: 'cpu')
    end


    # device
    describe '#device' do
      specify { expect(@component.device).to eql 'gar-test-1' }
    end

    # index
    describe '#index' do
      specify { expect(@component.index).to eql '103' }
    end

    # description
    describe '#description' do
      specify { expect(@component.description).to eql '' }
    end

    # update
    describe '#update' do
      obj = Component.new(device: 'gar-test-1', index: '103', hw_type: 'cpu')
      obj.update(data1_update_ok, worker: 'test')

      specify { expect(obj).to be_a Component }
      specify { expect(obj.description).to eql "Linecard(slot 1)" }
      specify { expect(obj.last_updated).to be > Time.now.to_i - 1000 }
    end
    
    # last_updated
    describe '#last_updated' do
      specify { expect(@component.last_updated).to eql 0 }
    end

  end


  context 'when populated' do

    before(:each) do
      @component1 = Component.new(device: 'gar-b11u1-dist', index: '7.1.0.0', hw_type: 'cpu')
      @component1.populate(data1_base)
      @component2 = Component.new(device: 'gar-k11u1-dist', index: '1', hw_type: 'cpu')
      @component2.populate(data2_base)
      @component3 = Component.new(device: 'gar-k11u1-dist', index: '1', hw_type: 'cpu')
      @component3.populate(data3_base)
    end


    # device
    describe '#device' do
      specify { expect(@component1.device).to eql 'gar-b11u1-dist' }
      specify { expect(@component2.device).to eql 'gar-k11u1-dist' }
      specify { expect(@component3.device).to eql 'gar-k11u1-dist' }
    end

    # index
    describe '#index' do
      specify { expect(@component1.index).to eql '7.1.0.0' }
      specify { expect(@component2.index).to eql '1' }
      specify { expect(@component3.index).to eql '1' }
    end

    # description
    describe '#description' do
      specify { expect(@component1.description).to eql "Linecard(slot 1)" }
      specify { expect(@component2.description).to eql "FPC: EX4300-48T @ 1/*/*" }
      specify { expect(@component3.description).to eql "Component 768" }
    end

    # update
    describe '#update' do
      specify { expect(@component1.update(data1_update_ok, worker: 'test')).to be_a Component }
      specify { expect(@component2.update(data2_update_ok, worker: 'test')).to be_a Component }
      specify { expect(@component3.update(data3_update_ok, worker: 'test')).to be_a Component }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@component1.last_updated).to eql data1_base['last_updated'].to_i }
      specify { expect(@component2.last_updated).to eql data2_base['last_updated'].to_i }
      specify { expect(@component3.last_updated).to eql data3_base['last_updated'].to_i }
    end

  end


end
