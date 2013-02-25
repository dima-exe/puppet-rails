require 'spec_helper'

describe 'rails::database' do
  let(:title)  { 'my-app-title' }

  let(:default_params) { {
    :application   => 'my-app',
    :rails_env     => 'staging',
    :db_adapter    => 'db-user',
    :db_user       => 'db-user',
    :db_password   => 'db-pass',
    :db_host       => 'example.com',
  } }
  let(:mysql2_params){ { :db_adapter => "mysql2" } }
  let(:postgresql_params){ { :db_adapter => "postgresql" } }
  let(:params){ default_params }

  context "when $db_adapter is 'mysql2'" do
    let(:facts) { {:osfamily => 'Debian' } }
    let(:params){ default_params.merge mysql2_params }

    it { should include_class("mysql::server") }

    it do should contain_resource("Database_user[db-user@%]").with(
            :password_hash => '*45F8C661CF22C14CF93F23E62B4DA8E9BAB749E0',
            :require => 'Class[Mysql::Config]',
    ) end

    it do should contain_resource("Database_grant[db-user@%]").with(
            :privileges => ['all'],
            :require    => 'Database_user[db-user@%]'
    ) end

    it do should contain_resource("Database[my-app_staging]").with(
            :charset => 'utf8',
            :require => 'Database_user[db-user@%]'
    ) end

    context "when $databases present" do
      let(:params){ mysql2_params.merge :databases => ["db1","db2"] }

      it "should contain many databases" do
        should contain_resource("Database[db1]")
        should contain_resource("Database[db2]")
      end
    end

    context "when $db_host is localhost" do
      let(:params){ mysql2_params.merge :db_host => "localhost" }
      it { should contain_resource("Database_user[my-app-title@localhost]") }
      it { should contain_resource("Database_grant[my-app-title@localhost]") }
    end
  end

  context "when $db_adapter is 'postgresql'" do
    let(:params){ default_params.merge postgresql_params }
    let(:facts) { { :postgres_default_version => '9.1',
                    :osfamily => 'Debian',
                    :concat_basedir => '/' }  }

    it { should include_class("postgresql::server") }

    it do should contain_resource("Postgresql::Database[my-app_staging]").with(
      :require => "Class[Postgresql::Config]"
    ) end

    it do should contain_resource("Postgresql::Role[db-user]").with(
      :password_hash => 'md57a92eb136ee03d15505e7eacc40cb981',
      :superuser     => true,
      :login         => true,
      :createdb      => true,
      :require       => 'Class[Postgresql::Config]'
    ) end

    context "when $databases present" do
      let(:params){ postgresql_params.merge :databases => ["db1","db2"] }

      it "should contain many databases" do
        should contain_resource("Postgresql::Database[db1]")
        should contain_resource("Postgresql::Database[db2]")
      end
    end
  end
end



