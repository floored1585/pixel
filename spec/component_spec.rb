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
        id = Component.id(device: 'gar-b11u1-dist', index: '7.2.0.0', hw_type: 'CPU')
        expect(id).to be_a Numeric
        expect(id).to be > 0
      end

    end

    context 'when component does not exist' do

      it 'should return nil' do
        id = Component.id(device: 'gar-invalid-device', index: '7.2.0.0', hw_type: 'CPU')
        expect(id).to eql nil
      end

    end

  end


  # id_from_db
  describe '#id_from_db' do

    context 'when component exists' do

      it 'should return the right id' do
        id = Component.id_from_db(device: 'gar-b11u1-dist', index: '7.2.0.0', hw_type: 'CPU', db: DB)
        expect(id).to be_a Numeric
        expect(id).to be > 0
      end

    end

    context 'when component does not exist' do

      it 'should return nil' do
        id = Component.id_from_db(device: 'gar-whatever-invalid', index: '7.2.0.0', hw_type: 'CPU', db: DB)
        expect(id).to eql nil
      end

    end

  end


  # Fetch_from_db
  describe '#fetch_from_db' do

    before :each do
      # Insert our bare bones device and component
      DB[:device].insert(:device => 'test-v11u1-acc-y', :ip => '1.2.3.4')
      @component_id = DB[:component].insert(
        :hw_type => 'CPU',
        :device => 'test-v11u1-acc-y',
        :index => '1',
        :last_updated => '12345678',
        :description => 'CPU 1',
        :worker => 'rspec',
      )
      # Insert the component itself
      DB[:cpu].insert(
        :component_id => @component_id,
        :util => 54,
      )
    end
    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-v11u1-acc-y').delete
    end


    it 'should return an array' do
      expect(Component.fetch_from_db(hw_types: ['CPU'], device: 'test-v11u1-acc-y', index: 1, db: DB)).to be_an Array
    end

    it 'should return a Component' do
      expect(Component.fetch_from_db(hw_types: ['CPU'], device: 'test-v11u1-acc-y', index: 1, db: DB).first).to be_a Component
    end

    it 'should return the right Component' do
      expect(Component.fetch_from_db(hw_types: ['CPU'], device: 'test-v11u1-acc-y', index: 1, db: DB).first).to be_a CPU
    end

    it 'should respect a limit' do
      expect(Component.fetch_from_db(hw_types: ['CPU'], db: DB, limit: 10).length).to be 10
    end

  end


  # populate
  describe '#populate' do
    it 'should fill up the object' do
      good = Component.new(device: 'iad1-bdr-1', index: '1.4.0', hw_type: 'CPU')
      expect(JSON.parse(good.populate(data1_base).to_json)['data'].keys.sort).to eql json_keys
    end
    it 'should return nil if no data passed' do
      good = Component.new(device: 'iad1-bdr-1', index: '1.4.0', hw_type: 'CPU')
      expect(good.populate({})).to eql nil
    end
  end


  context 'when freshly created' do

    before(:each) do
      @component = Component.new(device: 'gar-test-1', index: '103', hw_type: 'CPU')
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
      obj = Component.new(device: 'gar-test-1', index: '103', hw_type: 'CPU')
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
      @component1 = Component.new(device: 'gar-b11u1-dist', index: '7.1.0.0', hw_type: 'CPU')
      @component1.populate(data1_base)
      @component2 = Component.new(device: 'gar-k11u1-dist', index: '1', hw_type: 'CPU')
      @component2.populate(data2_base)
      @component3 = Component.new(device: 'gar-k11u1-dist', index: '1', hw_type: 'CPU')
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
