require_relative 'rspec'
require_relative '../lib/api'
require_relative '../lib/device'


describe API do


  describe '#get' do

    good_url = '/v2/device/iad1-bdr-1'
    bad_url = '/doesNotExist'


    context 'when correctly formatted + defaults' do
      rsp = API.get(
        src: 'rspec', dst: 'core',
        resource: good_url, what: 'test device'
      )
      specify { expect(rsp).to be_a Device }
    end

    context 'when corretly formatted + no retries' do
      rsp = API.get(
        src: 'rspec', dst: 'core',
        resource: good_url, what: 'test device', retries: 0
      )
      specify { expect(rsp).to be_a Device }
    end

    context 'when incorrectly formatted + defaults' do
      start = Time.now.to_i
      rsp = API.get(
        src: 'rspec', dst: 'core',
        resource: bad_url, what: 'test device'
      )
      finish = Time.now.to_i
      it 'should return false' do
        expect(rsp).to eql false
      end
      it 'should take some time to fail' do
        expect(finish - start).to be >= 5
      end
    end

    context 'when incorrectly formatted + 0 retries' do
      start = Time.now.to_i
      rsp = API.get(
        src: 'rspec', dst: 'core',
        resource: bad_url, what: 'test device', retries: 0
      )
      finish = Time.now.to_i
      it 'should return false' do
        expect(rsp).to eql false
      end
      it 'should fail instantly' do
        expect(finish - start).to be <= 1
      end
    end

    context 'when incorrectly formatted + 1 retry' do
      start = Time.now.to_i
      rsp = API.get(
        src: 'rspec', dst: 'core',
        resource: bad_url, what: 'test device', retries: 1
      )
      finish = Time.now.to_i
      it 'should return false' do
        expect(rsp).to eql false
      end
      it 'should take some time to fail' do
        expect(finish - start).to be > 1
      end
    end

    context 'when incorrectly formatted + 1 retry and 2 second delay' do
      start = Time.now.to_i
      rsp = API.get(
        src: 'rspec', dst: 'core', resource: bad_url,
        what: 'test device', retries: 1, delay: 2,
      )
      finish = Time.now.to_i
      it 'should return false' do
        expect(rsp).to eql false
      end
      it 'should take some time to fail' do
        expect(finish - start).to be_within(1).of(2)
      end
    end

  end


  describe '#post' do

    valid_device = Device.new('test-api-post', poll_ip: '1.2.3.4')
    valid_device_url = '/v2/device/test-api-post'
    invalid_device = Device.new('test-test-dist')

    after :each do
      # Clean up DB
      DB[:device].where(:device => 'test-api-post').delete
    end


    context 'when correctly formatted with a valid object' do

      it 'should return 200' do
        rsp = API.post(
          src: 'rspec', dst: 'core', resource: '/v2/device',
          what: 'test device', data: valid_device,
        )
        expect(rsp).to eql true
      end

      it 'should update the database' do
        rsp = API.post(
          src: 'rspec', dst: 'core', resource: '/v2/device',
          what: 'test device', data: valid_device,
        )
        device = Device.fetch('test-api-post')
        expect(device).to be_a Device
      end

    end

    context 'when correctly formatted with an invalid object' do

      it 'should return false' do
        rsp = API.post(
          src: 'rspec', dst: 'core', resource: '/v2/device',
          what: 'test device', data: invalid_device, retries: 0,
        )
        device = Device.fetch('test-api-post')
        expect(rsp).to eql false
      end

      it 'should not update the database' do
        rsp = API.post(
          src: 'rspec', dst: 'core', resource: '/v2/device',
          what: 'test device', data: invalid_device, retries: 0,
        )
        device = Device.fetch('test-api-post')
        expect(device).to eql nil
      end

    end

    context 'when incorrectly formatted' do

      it 'should return false' do
        rsp = API.post(
          src: 'rspec', dst: 'core', resource: '/v2/badURL',
          what: 'test device', data: invalid_device, retries: 0,
        )
        device = Device.fetch('test-api-post')
        expect(rsp).to eql false
      end

    end

  end


end
