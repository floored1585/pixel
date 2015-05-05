require_relative 'rspec'
require_relative 'objects'

describe Device do


  test_devices = {
   'Cisco 2960' => 'gar-b11u17-acc-g',
   'Cisco 4948' => 'irv-i1u1-dist',
   'Cumulus' => 'aon-cumulus-2',
   'Juniper EX' => 'gar-p1u1-dist',
   'Juniper MX' => 'gar-bdr-1',
   'Force10 S4810' => 'iad1-trn-1',
  }


  describe '#poll' do

    context 'when newly created with name' do
      dev = Device.new('gar-c11u1-dist')

      specify { expect(dev.poll(worker: 'test-worker', uuid: 'blah')).to eql nil }
    end

    context 'when newly created with name and IP' do
      dev = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_device = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_interfaces = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_temperatures = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_fans = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_psus = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_cpus = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_memory = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')
      dev_all = Device.new('irv-i1u1-dist', poll_ip: '208.113.142.180')

      dev.poll(worker: 'test-worker', uuid: 'blah')
      dev_device.poll(worker: 'test-worker', uuid: 'blah', items: [])
      dev_interfaces.poll(worker: 'test-worker', uuid: 'blah', items: [:interfaces])
      dev_temperatures.poll(worker: 'test-worker', uuid: 'blah', items: [:temperatures])
      dev_fans.poll(worker: 'test-worker', uuid: 'blah', items: [:fans])
      dev_psus.poll(worker: 'test-worker', uuid: 'blah', items: [:psus])
      dev_cpus.poll(worker: 'test-worker', uuid: 'blah', items: [:cpus])
      dev_memory.poll(worker: 'test-worker', uuid: 'blah', items: [:memory])
      dev_all.poll(worker: 'test-worker', uuid: 'blah', items: [:all])

      context 'and when all items polled' do
        it 'should return a Device object' do
          expect(dev).to be_a Device
          expect(dev_all).to be_a Device
        end
        it 'should have Interface objects' do
          expect(dev.interfaces.values.first).to be_a Interface
          expect(dev_all.interfaces.values.first).to be_a Interface
        end
        it 'should have Temperature objects' do
          expect(dev.temps.values.first).to be_a Temperature
          expect(dev_all.temps.values.first).to be_a Temperature
        end
        it 'should have Fan objects' do
          expect(dev.fans.values.first).to be_a Fan
          expect(dev_all.fans.values.first).to be_a Fan
        end
        it 'should have PSU objects' do
          expect(dev.psus.values.first).to be_a PSU
          expect(dev_all.psus.values.first).to be_a PSU
        end
        it 'should have CPU objects' do
          expect(dev.cpus.values.first).to be_a CPU
          expect(dev_all.cpus.values.first).to be_a CPU
        end
        it 'should have Memory objects' do
          expect(dev.memory.values.first).to be_a Memory
          expect(dev_all.memory.values.first).to be_a Memory
        end
        it 'should know the worker' do
          expect(dev.worker).to eql 'test-worker'
          expect(dev_all.worker).to eql 'test-worker'
        end
      end
      context 'and when an empty items array passed' do
        it 'should return a Device object' do
          expect(dev_device).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_device.interfaces.values.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_device.temps.values.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_device.fans.values.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_device.psus.values.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_device.cpus.values.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_device.memory.values.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_device.worker).to eql 'test-worker'
        end
      end
      context 'and when only interfaces polled' do
        it 'should return a Device object' do
          expect(dev_interfaces).to be_a Device
        end
        it 'should have Interface objects' do
          expect(dev_interfaces.interfaces.values.first).to be_a Interface
        end
        it 'should not have Temperature objects' do
          expect(dev_interfaces.temps.values.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_interfaces.fans.values.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_interfaces.psus.values.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_interfaces.cpus.values.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_interfaces.memory.values.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_interfaces.worker).to eql 'test-worker'
        end
      end
      context 'and when only temperatures polled' do
        it 'should return a Device object' do
          expect(dev_temperatures).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_temperatures.interfaces.values.first).to eql nil
        end
        it 'should have Temperature objects' do
          expect(dev_temperatures.temps.values.first).to be_a Temperature
        end
        it 'should not have Fan objects' do
          expect(dev_temperatures.fans.values.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_temperatures.psus.values.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_temperatures.cpus.values.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_temperatures.memory.values.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_temperatures.worker).to eql 'test-worker'
        end
      end
      context 'and when only fans polled' do
        it 'should return a Device object' do
          expect(dev_fans).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_fans.interfaces.values.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_fans.temps.values.first).to eql nil
        end
        it 'should have Fan objects' do
          expect(dev_fans.fans.values.first).to be_a Fan
        end
        it 'should not have PSU objects' do
          expect(dev_fans.psus.values.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_fans.cpus.values.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_fans.memory.values.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_fans.worker).to eql 'test-worker'
        end
      end
      context 'and when only psus polled' do
        it 'should return a Device object' do
          expect(dev_psus).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_psus.interfaces.values.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_psus.temps.values.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_psus.fans.values.first).to eql nil
        end
        it 'should have PSU objects' do
          expect(dev_psus.psus.values.first).to be_a PSU
        end
        it 'should not have CPU objects' do
          expect(dev_psus.cpus.values.first).to eql nil
        end
        it 'should not have Memory objects' do
          expect(dev_psus.memory.values.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_psus.worker).to eql 'test-worker'
        end
      end
      context 'and when only cpus polled' do
        it 'should return a Device object' do
          expect(dev_cpus).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_cpus.interfaces.values.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_cpus.temps.values.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_cpus.fans.values.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_cpus.psus.values.first).to eql nil
        end
        it 'should have CPU objects' do
          expect(dev_cpus.cpus.values.first).to be_a CPU
        end
        it 'should not have Memory objects' do
          expect(dev_cpus.memory.values.first).to eql nil
        end
        it 'should know the worker' do
          expect(dev_cpus.worker).to eql 'test-worker'
        end
      end
      context 'and when only memory polled' do
        it 'should return a Device object' do
          expect(dev_memory).to be_a Device
        end
        it 'should not have Interface objects' do
          expect(dev_memory.interfaces.values.first).to eql nil
        end
        it 'should not have Temperature objects' do
          expect(dev_memory.temps.values.first).to eql nil
        end
        it 'should not have Fan objects' do
          expect(dev_memory.fans.values.first).to eql nil
        end
        it 'should not have PSU objects' do
          expect(dev_memory.psus.values.first).to eql nil
        end
        it 'should not have CPU objects' do
          expect(dev_memory.cpus.values.first).to eql nil
        end
        it 'should have Memory objects' do
          expect(dev_memory.memory.values.first).to be_a Memory
        end
        it 'should know the worker' do
          expect(dev_memory.worker).to eql 'test-worker'
        end
      end

    end

    test_devices.each do |label, device|
      context "on a #{label} when populated" do
        dev_obj = Device.fetch(device)
        specify { expect(dev_obj.poll(worker: 'test-worker', uuid: 'blah')).to be_a Device }
      end
    end

  end


end
