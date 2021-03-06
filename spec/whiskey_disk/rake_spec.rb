require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require 'rake'

describe 'rake tasks' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'rake.rb'))
    WhiskeyDisk.reset
  end

  after do
    Rake.application = nil
  end
  
  describe 'deploy:setup' do
    before do
      @configuration = { }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      [ 
        :ensure_main_parent_path_is_present, 
        :ensure_config_parent_path_is_present,
        :checkout_main_repository,
        :install_hooks,
        :checkout_configuration_repository,
        :update_main_repository_checkout,
        :update_configuration_repository_checkout,
        :refresh_configuration,
        :run_post_setup_hooks, 
        :flush
      ].each do |meth| 
        WhiskeyDisk.stub!(meth) 
      end
    end
    
    it 'should make changes on the specified domain when a domain is specified' do
      @configuration = { 'domain' => 'some domain' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      @rake["deploy:setup"].invoke
      WhiskeyDisk.should.be.remote
    end
    
    it 'should make changes on the local system when no domain is specified' do
      @configuration = { 'domain' => '' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)        
      WhiskeyDisk.should.not.be.remote
    end
    
    it 'should ensure that the parent path for the main repository checkout is present' do
      WhiskeyDisk.should.receive(:ensure_main_parent_path_is_present)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when a configuration repo is specified' do
      it 'should ensure that the parent path for the configuration repository checkout is present' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(true)
        WhiskeyDisk.should.receive(:ensure_config_parent_path_is_present)
        @rake["deploy:setup"].invoke    
      end
    end
    
    describe 'when no configuration repo is specified' do
      it 'should not ensure that the path for the configuration repository checkout is present' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(false)
        WhiskeyDisk.should.not.receive(:ensure_config_parent_path_is_present)
        @rake["deploy:setup"].invoke        
      end
    end
    
    it 'should check out the main repository' do
      WhiskeyDisk.should.receive(:checkout_main_repository)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when a configuration repository is specified' do
      it 'should check out the configuration repository' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(true)
        WhiskeyDisk.should.receive(:checkout_configuration_repository)
        @rake["deploy:setup"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'should not check out the configuration repository' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(false)
        WhiskeyDisk.should.not.receive(:checkout_configuration_repository)
        @rake["deploy:setup"].invoke
      end
    end
    
    it 'should update the main repository checkout' do
      WhiskeyDisk.should.receive(:update_main_repository_checkout)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when a configuration repository is specified' do
      it 'should update the configuration repository checkout' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(true)
        WhiskeyDisk.should.receive(:update_configuration_repository_checkout)
        @rake["deploy:setup"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'should update the configuration repository checkout' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(false)
        WhiskeyDisk.should.not.receive(:update_configuration_repository_checkout)
        @rake["deploy:setup"].invoke
      end
    end

    describe 'when a configuration repository is specified' do      
      it 'should refresh the configuration' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(true)
        WhiskeyDisk.should.receive(:refresh_configuration)
        @rake["deploy:setup"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do      
      it 'should not refresh the configuration' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(false)
        WhiskeyDisk.should.not.receive(:refresh_configuration)
        @rake["deploy:setup"].invoke
      end
    end
    
    it 'should run any post setup hooks' do        
      WhiskeyDisk.should.receive(:run_post_setup_hooks)
      @rake["deploy:setup"].invoke
    end
    
    it 'should flush WhiskeyDisk changes' do
      WhiskeyDisk.should.receive(:flush)
      @rake["deploy:setup"].invoke
    end
  end
  
  describe 'deploy:now' do
    before do
      @configuration = { }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      [ 
        :enable_staleness_checks,
        :update_main_repository_checkout,
        :update_configuration_repository_checkout,
        :refresh_configuration,
        :run_post_deploy_hooks,
        :flush
      ].each do |meth| 
        WhiskeyDisk.stub!(meth) 
      end
    end
    
    it 'should make changes on the specified domain when a domain is specified' do
      @configuration = { 'domain' => 'some domain'}
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      @rake["deploy:now"].invoke
      WhiskeyDisk.should.be.remote
    end
    
    it 'should make changes on the local system when no domain is specified' do
      WhiskeyDisk.should.not.be.remote
    end
    
    it 'should enable staleness checks' do
      WhiskeyDisk.should.receive(:enable_staleness_checks)
      @rake["deploy:now"].invoke
    end
    
    it 'should update the main repository checkout' do
      WhiskeyDisk.should.receive(:update_main_repository_checkout)
      @rake["deploy:now"].invoke
    end
    
    describe 'when a configuration repository is specified' do
      it 'should update the configuration repository checkout' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(true)
        WhiskeyDisk.should.receive(:update_configuration_repository_checkout)
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'should not update the configuration repository checkout' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(false)
        WhiskeyDisk.should.not.receive(:update_configuration_repository_checkout)
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when a configuration repository is specified' do
      it 'should refresh the configuration' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(true)
        WhiskeyDisk.should.receive(:refresh_configuration)
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'should not refresh the configuration' do
        WhiskeyDisk.stub!(:has_config_repo?).and_return(false)
        WhiskeyDisk.should.not.receive(:refresh_configuration)
        @rake["deploy:now"].invoke
      end
    end
    
    it 'should run any post deployment hooks' do        
      WhiskeyDisk.should.receive(:run_post_deploy_hooks)
      @rake["deploy:now"].invoke
    end
    
    it 'should flush WhiskeyDisk changes' do
      WhiskeyDisk.should.receive(:flush)
      @rake["deploy:now"].invoke
    end
  end
      
  describe 'deploy:post_setup' do
    it 'should run the defined post_setup rake task when a post_setup rake task is defined for this environment' do
      @configuration = { 'environment' => 'production'}
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      WhiskeyDisk.reset      

      task "deploy:production:post_setup" do
        WhiskeyDisk.fake_method
      end

      WhiskeyDisk.should.receive(:fake_method)
      Rake::Task['deploy:post_setup'].invoke
    end

    it 'should not fail when no post_setup rake task is defined for this environment' do
      @configuration = { 'environment' => 'staging'}
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      WhiskeyDisk.reset      
      lambda { Rake::Task['deploy:post_setup'].invoke }.should.not.raise
    end
  end
  
  describe 'deploy:post_deploy' do
    it 'should run the defined post_deploy rake task when a post_deploy rake task is defined for this environment' do
      @configuration = { 'environment' => 'production'}
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      WhiskeyDisk.reset      

      task "deploy:production:post_deploy" do
        WhiskeyDisk.fake_method
      end

      WhiskeyDisk.should.receive(:fake_method)
      Rake::Task['deploy:post_deploy'].invoke
    end

    it 'should not fail when no post_deploy rake task is defined for this environment' do
      @configuration = { 'environment' => 'staging'}
      WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
      WhiskeyDisk.reset      
      lambda { Rake::Task['deploy:post_deploy'].invoke }.should.not.raise
    end
  end
end
