FactoryBot.define do
  factory :orchestration_template_telefonica_in_json,
          :parent => :orchestration_template,
          :class  => "ManageIQ::Providers::Telefonica::CloudManager::OrchestrationTemplate" do
    content { File.read(ManageIQ::Providers::Telefonica::Engine.root.join(*%w(spec fixtures orchestration_templates heat_parameters.json))) }
  end

  factory :orchestration_template_telefonica_in_yaml,
          :parent => :orchestration_template,
          :class  => "ManageIQ::Providers::Telefonica::CloudManager::OrchestrationTemplate" do
    content { File.read(ManageIQ::Providers::Telefonica::Engine.root.join(*%w(spec fixtures orchestration_templates heat_parameters.yml))) }
  end

  factory :vnfd_template_telefonica_in_yaml,
          :parent => :orchestration_template,
          :class  => "ManageIQ::Providers::Telefonica::CloudManager::VnfdTemplate" do
    content { File.read(ManageIQ::Providers::Telefonica::Engine.root.join(*%w(spec fixtures orchestration_templates vnfd_parameters.yml))) }
  end
end
