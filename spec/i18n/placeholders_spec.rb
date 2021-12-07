describe :placeholders do
  include_examples :placeholders, ManageIQ::Providers::Telefonica::Engine.root.join('locale').to_s
end
