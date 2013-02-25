require 'spec_helper'

describe 'rails::deploy' do
  let(:title)  { 'my-app' }
  let(:params) { {
    :app_name    => 'my-rails-app',
    :deploy_path => '/u/apps',
    :app_user    => 'rails'
  } }

  it do should contain_user('rails').with(
          :system     => true,
          :home       => '/home/rails',
          :managehome => true,
          :shell      => '/bin/bash'
  ) end

  it do should contain_group('rails').with(
          :require => 'User[rails]',
  ) end

  it do should contain_file("/home/rails/.ssh").with(
          :mode  => '0700',
          :owner => 'rails',
          :group => 'rails',
          :require => "User[rails]"
  ) end

  context "with $keys" do
    let(:params) { { :keys => ["keys"], :app_user => "rails" } }

    it do should contain_file("/home/rails/.ssh/authorized_keys").with(
            :mode    => '0644',
            :content => 'keys',
            :owner   => 'rails',
            :require => "File[/home/rails/.ssh]"
    ) end
  end

  it do should contain_exec("rails:my-rails-app:dir").with(
          :command => "/bin/mkdir -p /u/apps/my-rails-app",
          :creates => "/u/apps/my-rails-app"
  ) end

  %w{ releases shared services }.each do |d|
    it do should contain_file("/u/apps/my-rails-app/#{d}").with(
            :owner   => 'rails',
            :mode    => '1775',
            :require => 'File[/u/apps/my-rails-app]'
    ) end
  end

  %w{ config log pids }.each do |d|
    it do should contain_file("/u/apps/my-rails-app/shared/#{d}").with(
            :owner   => 'rails',
            :mode    => '1775',
            :require => 'File[/u/apps/my-rails-app/shared]'
    ) end
  end

  it do should contain_file("/u/apps/my-rails-app/shared/config/settings").with(
          :owner   => 'rails',
          :require => 'File[/u/apps/my-rails-app/shared/config]'
  ) end

  context "without params" do
    let(:params) { Hash.new }
    it { should contain_file("/u/apps/my-app") }
    it { should contain_user("my-app") }
  end
end
