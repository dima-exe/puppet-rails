require 'spec_helper'

describe 'rails::application' do
  let(:title)  { 'my-app-title' }

  let(:default_params) { {
    :application   => 'my-app',
    :rails_env     => 'staging',
    :app_user      => 'app-user',
    :db_user       => 'db-user',
    :db_password   => 'db-pass',
    :db_host       => 'example.com',
    :db_pool       => 10,
    :num_instances => 5,
  } }
  let(:params){ default_params }
  let(:shared_dir){ "/u/apps/#{params[:application]}/shared" }

  it { should contain_class("runit") }

  it "should create resource Rails::Deploy" do
    should contain_resource("Rails::Deploy[my-app]").with(
      :deploy_path => "/u/apps",
      :app_user    => 'app-user',
      :deploy_keys => nil
    )
    should contain_file("#{shared_dir}/config")
  end

  it do should contain_file("#{shared_dir}/config/unicorn.rb").with(
          :owner       => 'app-user',
          :require     => 'File[/u/apps/my-app/shared/config]'
  ) end

  it do should contain_resource("Runit::Service[my-app]").with(
          :user        => 'app-user',
          :group       => 'app-user',
          :rundir      => "/u/apps/my-app/services",
          :command     => 'runsvdir /u/apps/my-app/services/current',
          :require     => 'File[/u/apps/my-app/services]'
  ) end

  context "with $deploy_keys" do
    let(:params){ { :deploy_keys => ['keys'] } }
    it do should contain_resource("Rails::Deploy[my-app-title]").with(
            :deploy_keys => ['keys']
    ) end
  end

  context "with $db_adapter" do
    let(:params) { default_params.merge(:db_adapter => "postgresql") }
    it do should contain_file("#{shared_dir}/config/database.yml").with(
            :owner => 'app-user',
            :content => File.read(File.expand_path(__FILE__ + "/../_database.yml")),
            :require     => 'File[/u/apps/my-app/shared/config]'
    ) end
  end

  context "with $resque_url" do
    let(:params) { default_params.merge(:resque_url => "url") }
    it do should contain_file("#{shared_dir}/config/resque.yml").with(
            :owner => 'app-user',
            :require     => 'File[/u/apps/my-app/shared/config]'
    ) end
  end
end
