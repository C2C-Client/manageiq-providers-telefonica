describe ManageIQ::Providers::Telefonica::CloudManager::Template do
  let(:ems) { FactoryBot.create(:ems_telefonica) }
  let(:image_attributes) { {'name' => 'test_image', 'description' => 'test_description'} }
  let(:template_telefonica) { FactoryBot.create :template_telefonica, :ext_management_system => ems, :ems_ref => 'one_id' }
  let(:service) { double }

  context 'when create_image' do
    before do
      allow(ems).to receive(:with_provider_connection).with(:service => 'Image').and_yield(service)
    end

    context 'with correct data' do
      it 'should create image' do
        expect(service).to receive(:create_image).with(image_attributes).once
        subject.class.create_image(ems, image_attributes)
      end

      it 'should not raise error' do
        allow(service).to receive(:create_image).with(image_attributes).once
        expect do
          (subject.class.create_image(ems, image_attributes)).not_to raise_error
        end
      end
    end

    context 'with incorrect data' do
      [Excon::Error::BadRequest, ArgumentError].map do |error|
        it "should raise error when #{error}" do
          allow(service).to receive(:create_image).with(image_attributes).and_raise(error)
          expect do
            (subject.class.create_image(ems, image_attributes)).to raise_error(MiqException::MiqTelefonicaApiRequestError)
          end
        end
      end
    end
  end

  context 'when update_image' do
    let(:fog_image) { double }
    let(:service) { double("Service", :images => double("Images", :find_by_id => fog_image)) }
    before do
      allow(ems).to receive(:with_provider_connection).with(:service => 'Image').and_yield(service)
      allow(template_telefonica).to receive(:ext_management_system).and_return(ems)
    end

    subject { template_telefonica }

    it 'should update image' do
      expect(subject).to receive(:update_image).with(image_attributes).once
      subject.update_image(image_attributes)
    end
  end

  context 'when raw_delete_image' do
    before do
      allow(ExtManagementSystem).to receive(:find).with(ems.id).and_return(ems)
      allow(ems).to receive(:with_provider_connection).with(:service => 'Image').and_yield(service)
    end

    subject { template_telefonica }

    it 'should delete image' do
      expect(service).to receive(:delete_image).with(template_telefonica.ems_ref).once
      subject.delete_image
    end

    it 'should raise error' do
      allow(service).to receive(:delete_image).with(template_telefonica.ems_ref).and_raise(Excon::Error::BadRequest)
      expect do
        (subject.delete_image).to raise_error(MiqException::MiqTelefonicaApiRequestError)
      end
    end
  end
end
