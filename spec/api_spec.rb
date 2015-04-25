require_relative 'rspec'
require_relative '../lib/api'
require_relative '../lib/device'
require_relative '../lib/configfile'

settings = Configfile.retrieve

good_get_url = '/v2/device/iad1-bdr-1'
bad_get_url = '/doesNotExist'
valid_device = Device.new('test-api-post', poll_ip: '1.2.3.4')
valid_device_url = '/v2/device/test-api-post'
invalid_device = Device.new('test-test-dist')


describe API do


  describe '#get' do

    context 'when correctly formatted + defaults' do
      specify { expect(API.get('core', good_get_url, 'RSPEC', 'rspec test')).to be_a Device }
    end

    context 'when corretly formatted + no retries' do
      specify { expect(API.get('core', good_get_url, 'RSPEC', 'rspec test', 0)).to be_a Device }
    end

    context 'when incorrectly formatted + defaults' do
      start = Time.now.to_i
      result = API.get('core', bad_get_url, 'RSPEC', 'rspec test')
      finish = Time.now.to_i
      it 'should return false' do
        expect(result).to eql false
      end
      it 'should take some time to fail' do
        expect(finish - start).to be >= 5
      end
    end

    context 'when incorrectly formatted + 0 retries' do
      start = Time.now.to_i
      result = API.get('core', bad_get_url, 'RSPEC', 'rspec test', 0)
      finish = Time.now.to_i
      it 'should return false' do
        expect(result).to eql false
      end
      it 'should fail instantly' do
        expect(finish - start).to be <= 1
      end
    end

    context 'when incorrectly formatted + 1 retry' do
      start = Time.now.to_i
      result = API.get('core', bad_get_url, 'RSPEC', 'rspec test', 1)
      finish = Time.now.to_i
      it 'should return false' do
        expect(result).to eql false
      end
      it 'should take some time to fail' do
        expect(finish - start).to be > 1
      end
    end

  end


  describe '#post' do

    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-api-post').delete
    end


    context 'when correctly formatted with a valid object' do

      it 'should return 200' do
        result = API.post('core', '/v2/device', valid_device, 'RSPEC', 'test post')
        device = Device.fetch('test-api-post')
        expect(result.status).to eql 200
      end

      it 'should update the database' do
        result = API.post('core', '/v2/device', valid_device, 'RSPEC', 'test post')
        device = Device.fetch('test-api-post')
        expect(device).to be_a Device
      end

    end

    context 'when correctly formatted with an invalid object' do

      it 'should return false' do
        result = API.post('core', '/v2/device', invalid_device, 'RSPEC', 'test post', 0)
        device = Device.fetch('test-api-post')
        expect(result).to eql false
      end

      it 'should update the database' do
        result = API.post('core', '/v2/device', invalid_device, 'RSPEC', 'test post', 0)
        device = Device.fetch('test-api-post')
        expect(device).to eql nil
      end

    end

    context 'when incorrectly formatted' do

      it 'should return false' do
        result = API.post('core', '/v2/badURL', valid_device, 'RSPEC', 'test post', 0)
        device = Device.fetch('test-api-post')
        expect(result).to eql false
      end

    end

  end


end
