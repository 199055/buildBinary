require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Buildbinary do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ buildBinary }).should.be.instance_of Command::Buildbinary
      end
    end
  end
end

