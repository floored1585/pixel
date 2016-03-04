#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative '../rspec'

describe Temperature do

  json_keys = [ 'device', 'index', 'temperature', 'last_updated', 'description',
                'status', 'threshold', 'vendor_status', 'status_text', 'worker' ].sort

  data1_base = {
    "device" => "gar-b11u1-dist", "index" => "7.1.0.0", "temperature" => 52, "worker" => "test123",
    "last_updated" => 1426657712,"description" => "FPC=> EX4300-48T @ 0/*/*", "status" => 0,
    "threshold" => 95,"vendor_status" => 1,"status_text" => "Unknown" }
  data2_base = {
    "device" => "gar-k11u1-dist", "index" => "1", "temperature" => 38, "worker" => "test123",
    "last_updated" => 1426657935,"description" => "Chassis Temperature Sensor", "status" => 1,
    "threshold" => 95,"vendor_status" => 1,"status_text" => "OK" }
  imaginary_data = {
    "device" => "test-test-1", "index" => "1", "temperature" => 38, "worker" => "test123",
    "last_updated" => 1426657935,"description" => "Chassis Temperature Sensor", "status" => 1,
    "threshold" => 95,"vendor_status" => 1,"status_text" => "OK" }

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

      it 'should have hw_type Temperature' do
        expect(Temperature.new(device: 'gar-test-1', index: 103).hw_type).to eql 'Temperature'
      end

    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Temperature.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys.sort).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = Temperature.new(device: 'iad1-bdr-1', index: '1.4.0')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when freshly created' do

    before(:each) do
      @temp = Temperature.new(device: 'gar-test-1', index: '103')
    end


    # device
    describe '#device' do
      specify { expect(@temp.device).to eql 'gar-test-1' }
    end

    # index
    describe '#index' do
      specify { expect(@temp.index).to eql '103' }
    end

    # description
    describe '#description' do
      specify { expect(@temp.description).to eql '' }
    end

    # temp
    describe '#temp' do
      specify { expect(@temp.temp).to eql nil }
    end

    # status_text
    describe '#status_text' do
      specify { expect(@temp.status_text).to eql nil }
    end

    # update
    describe '#update' do
      obj = Temperature.new(device: 'gar-test-1', index: '103').update(data1_update_ok, worker: 'test')
      specify { expect(obj).to be_a Temperature }
      specify { expect(obj.description).to eql "FPC: EX4300-48T @ 0/*/*" }
      specify { expect(obj.temp).to eql 44 }
      specify { expect(obj.last_updated).to be > Time.now.to_i - 1000 }
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


    # device
    describe '#device' do
      specify { expect(@temp1.device).to eql 'gar-b11u1-dist' }
      specify { expect(@temp2.device).to eql 'gar-k11u1-dist' }
    end

    # index
    describe '#index' do
      specify { expect(@temp1.index).to eql '7.1.0.0' }
      specify { expect(@temp2.index).to eql '1' }
    end

    # description
    describe '#description' do
      specify { expect(@temp1.description).to eql 'FPC=> EX4300-48T @ 0/*/*' }
      specify { expect(@temp2.description).to eql 'Chassis Temperature Sensor' }
    end

    # temp
    describe '#temp' do
      specify { expect(@temp1.temp).to eql 52 }
      specify { expect(@temp2.temp).to eql 38 }
    end

    # status_text
    describe '#status_text' do
      specify { expect(@temp1.status_text).to eql 'Unknown' }
      specify { expect(@temp2.status_text).to eql 'OK' }
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
      temp = Temperature.fetch(device: 'test-v11u1-acc-y', index: '1005', hw_types: ['Temperature']).first
      expect(temp).to eql nil
    end

    it 'should fail if empty' do
      temp = Temperature.new(device: 'test-v11u1-acc-y', index: '1005')
      expect(temp.save(DB)).to eql nil
    end

    it 'should fail if device does not exist' do
      temp = Temperature.new(device: 'test-test-y', index: '1005').populate(imaginary_data)
      expect(temp.save(DB)).to eql nil
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      temp = Temperature.fetch(device: 'test-v11u1-acc-y', index: '1005', hw_types: ['Temperature']).first
      expect(temp).to be_a Temperature
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      temp = Temperature.fetch(device: 'test-v11u1-acc-y', index: '1005', hw_types: ['Temperature']).first
      expect(temp).to be_a Temperature
    end

    it 'should be identical before and after' do
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      temp = Temperature.fetch(device: 'test-v11u1-acc-y', index: '1005', hw_types: ['Temperature']).first
      expect(temp.to_json).to eql JSON.load(DEV2_JSON).temps['1005'].to_json
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
      JSON.load(DEV2_JSON).temps['1005'].save(DB)
      object = Temperature.new(device: 'test-v11u1-acc-y', index: '1005')
      expect(object.delete(DB)).to eql 1
    end

    it "should return 0 if nonexistant" do
      object = Temperature.new(device: 'test-v11u1-acc-y', index: '1005')
      expect(object.delete(DB)).to eql 0
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
        @temp1 = Temperature.fetch(device: 'gar-b11u1-dist', index: '7.1.0.0', hw_types: ['Temperature']).first
        @temp2 = Temperature.fetch(device: 'irv-i1u1-dist', index: '1', hw_types: ['Temperature']).first
        @temp3 = Temperature.fetch(device: 'gar-bdr-1', index: '4.2.5.0', hw_types: ['Temperature']).first
        @temp4 = Temperature.fetch(device: 'iad1-trn-1', index: '1', hw_types: ['Temperature']).first
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
