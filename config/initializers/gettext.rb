Vmdb::Gettext::Domains.add_domain(
  'ManageIQ_Providers_Telefonica',
  ManageIQ::Providers::Telefonica::Engine.root.join('locale').to_s,
  :po
)
