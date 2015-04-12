require_relative 'rspec'

describe Device do


  test_devices = {
   'Cisco 2960' => 'gar-b11u17-acc-g',
   'Cisco 4948' => 'irv-i1u1-dist',
   'Cumulus' => 'aon-cumulus-2',
   'Juniper EX' => 'gar-p1u1-dist',
   'Juniper MX' => 'iad1-bdr-1',
   'Force10 S4810' => 'iad1-trn-1',
  }


  # Constructor
  describe '#new' do

    it 'should raise' do
      expect{Device.new}.to raise_error ArgumentError
    end

    it 'should return' do
      device = Device.new('gar-b11u17-acc-g')
      expect(device).to be_a Device
    end

    it 'should return' do
      device = Device.new('gar-b11u17-acc-g', poll_ip: '172.24.7.54')
      expect(device).to be_a Device
    end

    it 'should take the right name' do
      device1 = Device.new('gar-c11u1-dist', poll_ip: '172.24.7.54')
      device2 = Device.new('gar-c11u1-dist', poll_ip: '172.24.7.54')
      expect(device1.name).to eql 'gar-c11u1-dist'
      expect(device2.name).to eql 'gar-c11u1-dist'
    end

  end


  # populate should work the same no matter what state the device is in
  describe '#populate' do

    test_devices.each do |label, device|
      context "on a #{label} when no options passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate).to equal dev_obj
        end
      end
      context "on a #{label} when :interfaces passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:interfaces => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :cpus passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:cpus => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :memory passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:memory => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :temperatures passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:temperatures => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :psus passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:psus => true)).to equal dev_obj
        end
      end
      context "on a #{label} when :fans passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:fans => true)).to equal dev_obj
        end
      end
      context "on a #{label} when all options passed" do
        it 'should equal' do
          dev_obj = Device.new(device)
          expect(dev_obj.populate(:all => true)).to equal dev_obj
        end
      end
    end

  end


  context 'when newly created' do

    before :each do
      @dev_name = Device.new('gar-b11u17-acc-g')
    end


    describe '#interfaces' do
      specify { expect(@dev_name.interfaces).to be_a Hash }
      specify { expect(@dev_name.interfaces.values.first).to eql nil }
    end

    describe '#temps' do
      specify { expect(@dev_name.temps).to be_a Hash }
      specify { expect(@dev_name.temps.values.first).to eql nil }
    end

    describe '#fans' do
      specify { expect(@dev_name.fans).to be_a Hash }
      specify { expect(@dev_name.fans.values.first).to eql nil }
    end

    describe '#psus' do
      specify { expect(@dev_name.psus).to be_a Hash }
      specify { expect(@dev_name.psus.values.first).to eql nil }
    end

    describe '#cpus' do
      specify { expect(@dev_name.cpus).to be_a Hash }
      specify { expect(@dev_name.cpus.values.first).to eql nil }
    end

    describe '#memory' do
      specify { expect(@dev_name.memory).to be_a Hash }
      specify { expect(@dev_name.memory.values.first).to eql nil }
    end

    describe '#get_interface' do
      specify { expect(@dev_name.get_interface(name: 'Fa0/1')).to eql nil }
      specify { expect(@dev_name.get_interface(index: '10001')).to eql nil }
      specify { expect(@dev_name.get_interface(index: 10001)).to eql nil }
      specify { expect(@dev_name.get_interface(index: 10001, name: 'Fa0/2')).to eql nil }
    end


  end


  context 'when populated' do

    dev1 = Device.new('gar-b11u17-acc-g').populate(:all => true)
    dev2 = Device.new('irv-i1u1-dist').populate(:all => true)

    describe '#interfaces' do
      specify { expect(dev1.interfaces).to be_a Hash }
      specify { expect(dev1.interfaces.values.first).to be_a Interface }
    end

    describe '#temps' do
      specify { expect(dev1.temps).to be_a Hash }
      specify { expect(dev2.temps.values.first).to be_a Temperature }
    end

    describe '#fans' do
      specify { expect(dev1.fans).to be_a Hash }
      specify { expect(dev2.fans.values.first).to be_a Fan }
    end

    describe '#psus' do
      specify { expect(dev1.psus).to be_a Hash }
      specify { expect(dev2.psus.values.first).to be_a PSU }
    end

    describe '#cpus' do
      specify { expect(dev1.cpus).to be_a Hash }
      specify { expect(dev2.cpus.values.first).to be_a CPU }
    end

    describe '#memory' do
      specify { expect(dev1.memory).to be_a Hash }
      specify { expect(dev2.memory.values.first).to be_a Memory }
    end

    describe '#get_interface' do
      specify { expect(dev1.get_interface(name: 'Fa0/1').name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(name: 'fa0/1').name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(index: '10001').name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(index: 10001).name).to eql 'Fa0/1' }
      specify { expect(dev1.get_interface(index: 10002, name: 'Fa0/1').name).to eql 'Fa0/2' }
      specify { expect(dev1.get_interface).to eql nil }
    end


  end

  # update_totals
  describe '#update_totals' do

    context 'when freshly created' do

      dev = Device.new('test')

      specify { expect(dev).to be_a Device }

      specify { expect(dev.bps_out).to eql 0 }
      specify { expect(dev.pps_out).to eql 0 }
      specify { expect(dev.discards_out).to eql 0 }
      specify { expect(dev.errors_out).to eql 0 }

    end

    context 'when fully populated' do

      dev = JSON.load(DEV1_JSON)

      specify { expect(dev).to be_a Device }

      specify { expect(dev.bps_out).to eql 3365960688 }
      specify { expect(dev.pps_out).to eql 465065 }
      specify { expect(dev.discards_out).to eql 5131 }
      specify { expect(dev.errors_out).to eql 500 }

    end

  end

  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @dev = Device.new('gar-test-1')
      end


      it 'should return a string' do
        expect(@dev.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @dev.to_json
        expect(JSON.load(json)).to be_a Device
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      c2960 = Device.new(test_devices['Cisco 2960']).populate(:all => true)
      c4948 = Device.new(test_devices['Cisco 4948']).populate(:all => true)
      cumulus = Device.new(test_devices['Cumulus']).populate(:all => true)
      ex = Device.new(test_devices['Juniper EX']).populate(:all => true)
      mx = Device.new(test_devices['Juniper MX']).populate(:all => true)
      f10_s4810 = Device.new(test_devices['Force10 S4810']).populate(:all => true)

      json_c2960 = c2960.to_json
      json_c4948 = c4948.to_json
      json_cumulus = cumulus.to_json
      json_ex = ex.to_json
      json_mx = mx.to_json
      json_f10_s4810 = f10_s4810.to_json

      specify { expect(JSON.load(json_c2960).to_json).to eql json_c2960 }
      specify { expect(JSON.load(json_c4948).to_json).to eql json_c4948 }
      specify { expect(JSON.load(json_cumulus).to_json).to eql json_cumulus }
      specify { expect(JSON.load(json_ex).to_json).to eql json_ex }
      specify { expect(JSON.load(json_mx).to_json).to eql json_mx }
      specify { expect(JSON.load(json_f10_s4810).to_json).to eql json_f10_s4810 }

      specify { expect(JSON.load(DEV1_JSON).to_json).to eql DEV1_JSON }
      specify { expect(JSON.load(DEV2_JSON).to_json).to eql DEV2_JSON }

    end

  end


  # True integration tests
  describe '#poll' do
    #c2960 = Device.new(test_devices['Cisco 2960']).populate.poll(worker: 't')
    #c4948 = Device.new(test_devices['Cisco 4948']).populate.poll(worker: 't')
    #cumulus = Device.new(test_devices['Cumulus']).populate.poll(worker: 't')
    #ex = Device.new(test_devices['Juniper EX']).populate.poll(worker: 't')
    #mx = Device.new(test_devices['Juniper MX']).populate.poll(worker: 't')
    #f10_s4810 = Device.new(test_devices['Force10 S4810']).populate.poll(worker: 't')

    context 'on a Cisco 2960' do
      #'Cisco 2960' => 'gar-b11u17-acc-g',
    end

    context 'on a Cisco 4948' do
      #'Cisco 4948' => 'irv-i1u1-dist',
    end

    context 'on a Cumulus device' do
      #'Cumulus' => 'aon-cumulus-2',
    end

    context 'on a Juniper EX' do
      #'Juniper EX' => 'gar-p1u1-dist',
    end

    context 'on a Juniper MX' do
      #'Juniper MX' => 'iad1-bdr-1',
    end

    context 'on a Force10 S4810' do
      #'Force10 S4810' => 'iad1-trn-1',
    end

  end

end
