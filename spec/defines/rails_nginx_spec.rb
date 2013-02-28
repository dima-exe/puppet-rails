require 'spec_helper'

describe 'rails::nginx' do
  let(:title)  { 'my-app-title' }

  let(:default_params) { {
    :application   => 'my-app',
  } }
  let(:params){ default_params }

  it { should contain_resource("Nginx::Site[my-app]") }
  it { should contain_class("nginx") }

  context "with default params" do
    let(:params){ Hash.new }
    it { should contain_resource("Nginx::Site[my-app-title]") }
  end
end

