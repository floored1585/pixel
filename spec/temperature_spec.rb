require_relative 'rspec'

describe Temperature do

  json_keys = [ 'device', 'index', 'temperature', 'last_updated', 'description',
                'status', 'threshold', 'vendor_status', 'status_text', 'worker' ]

  data1_base = {"device"=>"gar-b11u1-dist","index"=>"7.1.0.0","temperature"=>52,
                "last_updated"=>1426657712,"description"=>"FPC=> EX4300-48T @ 0/*/*","status"=>0,
                "threshold"=>nil,"vendor_status"=>nil,"status_text"=>"Unknown"}
  data2_base = {"device"=>"gar-k11u1-dist","index"=>"1","temperature"=>38,
                "last_updated"=>1426657935,"description"=>"Chassis Temperature Sensor","status"=>1,
                "threshold"=>95,"vendor_status"=>1,"status_text"=>"OK"}

  data1_decimal = {
    "description"=>"FPC: EX4300-48T @ 0/*/*",
    "temperature"=>"54.2",
    "status"=>0,
    "status_text"=>"Unknown"
  }
  data1_update_ok = {
    "description"=>"FPC: EX4300-48T @ 0/*/*",
    "temperature"=>"44",
    "status"=>1,
    "status_text"=>"OK"
  }
  data1_update_problem = {
    "description"=>"FPC: EX4300-48T @ 0/*/*",
    "temperature"=>"44",
    "status"=>2,
    "status_text"=>"Problem"
  }
  data2_update_ok = {
    "description"=>"Chassis Temperature Sensor",
    "threshold"=>"95",
    "vendor_status"=>"1",
    "temperature"=>"37",
    "status"=>1,
    "status_text"=>"OK"
  }


  # Constructor
  describe '#new' do

    context 'with good data' do
      it 'should return a Temperature object' do
        temp = Temperature.new(device: 'gar-test-1', index: 103)
        expect(temp).to be_a Temperature
      end
    end

  end


  # populate
  describe '#populate' do

    before :each do
      @bad_temp = Temperature.new(device: 'gar-test-1', index: 'test')
      @good_temp = Temperature.new(device: 'gar-p1u1-dist', index: '7.1.0.0')
    end


    it 'should return nil if the object does not exist' do
      expect(@bad_temp.populate).to eql nil
    end

    it 'should return an object if the object exists' do
      expect(@good_temp.populate).to be_a Temperature
    end

    it 'should fill up the object' do
      expect(JSON.parse(@good_temp.populate(data1_base).to_json)['data'].keys).to eql json_keys
    end

  end


  context 'when freshly created' do

    before(:each) do
      @temp = Temperature.new(device: 'gar-test-1', index: '103')
    end


    # update
    describe '#update' do
      specify { expect(@temp.update(data1_update_ok, worker: 'test')).to be_a Temperature }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@temp.last_updated).to eql 0 }
    end

  end


  context 'when populated' do

    before(:each) do
      @temp1 = Temperature.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
      @temp2 = Temperature.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
    end


    # update
    describe '#update' do
      specify { expect(@temp1.update(data1_update_ok, worker: 'test')).to be_a Temperature }
      specify { expect(@temp2.update(data2_update_ok, worker: 'test')).to be_a Temperature }
    end

    # last_updated
    describe '#last_updated' do
      specify { expect(@temp1.last_updated).to eql data1_base['last_updated'] }
      specify { expect(@temp2.last_updated).to eql data2_base['last_updated'] }
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
      temp = Temperature.new(device: 'test-v11u1-acc-y', index: '1005').populate
      expect(temp).to eql nil
    end

    it 'should error out if empty' do
      temp = Temperature.new(device: 'test-v11u1-acc-y', index: '1005')
      expect{temp.save(DB)}.to raise_error Sequel::NotNullConstraintViolation
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      temp = Temperature.new(device: 'test-v11u1-acc-y', index: '1005').populate
      expect(temp).to be_a Temperature
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      temp = Temperature.new(device: 'test-v11u1-acc-y', index: '1005').populate
      expect(temp).to be_a Temperature
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      temp = Temperature.new(device: 'test-v11u1-acc-y', index: '1005').populate
      expect(temp.to_json).to eql JSON.load(DEV2_JSON).temps['1005'].to_json
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @temp = Temperature.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@temp.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @temp.to_json
        expect(JSON.load(json)).to be_a Temperature
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      before(:each) do
        @temp1 = Temperature.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate
        @temp2 = Temperature.new(device: 'irv-i1u1-dist', index: '1').populate
        @temp3 = Temperature.new(device: 'gar-bdr-1', index: '4.2.5.0').populate
        @temp4 = Temperature.new(device: 'iad1-trn-1', index: '1').populate
      end


      it 'should serialize and deserialize properly' do
        json1 = @temp1.to_json
        json2 = @temp2.to_json
        json3 = @temp3.to_json
        json4 = @temp4.to_json
        expect(JSON.load(json1).to_json).to eql json1
        expect(JSON.load(json2).to_json).to eql json2
        expect(JSON.load(json3).to_json).to eql json3
        expect(JSON.load(json4).to_json).to eql json4
      end

    end

  end


end
