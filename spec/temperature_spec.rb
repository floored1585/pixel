require_relative '../lib/temperature'
require_relative '../lib/core_ext/object'

describe Temperature do

  json_keys = [ 'device', 'index', 'temperature', 'last_updated', 'description',
                'status', 'threshold', 'vendor_status', 'status_text' ]

  data1_base = {"device"=>"gar-b11u1-dist","index"=>"7.1.0.0","temperature"=>52,"last_updated"=>1426657712,"description"=>"FPC=> EX4300-48T @ 0/*/*","status"=>0,"threshold"=>nil,"vendor_status"=>nil,"status_text"=>"Unknown"}
  data2_base = {"device"=>"gar-k11u1-dist","index"=>"1","temperature"=>38,"last_updated"=>1426657935,"description"=>"Chassis Temperature Sensor","status"=>1,"threshold"=>95,"vendor_status"=>1,"status_text"=>"OK"}
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
      @temp = Temperature.new(device: 'gar-test-1', index: 'test')
    end

    it 'should return a Temperature object' do
      expect(@temp.populate(data1_base)).to be_a Temperature
    end

    it 'should fill up the object' do
      expect(JSON.parse(@temp.populate(data1_base).to_json).keys).to eql json_keys
    end


  end


  # update
  describe '#update' do

    context 'when freshly created' do

      before(:each) do
        @temp = Temperature.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a Temperature object' do
        expect(@temp.update(data1_update_ok)).to be_a Temperature
      end

    end


    context 'when populated' do

      before(:each) do
        @temp = Temperature.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @temp2 = Temperature.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
      end


      it 'should return a Temperature object' do
        expect(@temp.update(data1_update_ok)).to be_a Temperature
        expect(@temp2.update(data2_update_ok)).to be_a Temperature
      end

    end

  end

  # to_json
  describe '#to_json' do

    context 'when freshly created' do

      before(:each) do
        @temp = Temperature.new(device: 'gar-test-1', index: '103')
      end


      it 'should return a string' do
        expect(@temp.to_json).to be_a String
      end

      it 'should return empty' do
        expect(JSON.parse(@temp.to_json)).to be_empty
      end

    end


    context 'when populated' do

      before(:each) do
        @temp = Temperature.new(device: 'gar-b11u1-dist', index: '7.1.0.0').populate(data1_base)
        @temp2 = Temperature.new(device: 'gar-k11u1-dist', index: '1').populate(data2_base)
      end


      it 'should have all required keys' do
        expect(JSON.parse(@temp.update(data1_update_ok).to_json).keys).to eql json_keys
        expect(JSON.parse(@temp2.update(data2_update_ok).to_json).keys).to eql json_keys
      end

    end

  end


end
