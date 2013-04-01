require 'spec_helper'

class Vigil
  describe OS do

    describe '#system' do
      it do
        subject.system("true").should be_true
      end

      context 'when it fails' do
        it 'should raise an error' do
          os = OS.new
          expect {
            os.system('false')
          }.to raise_error('Failed')
        end

        it 'should call the block if one is given' do
          os = OS.new
          called = false
          a_block = ->(stat){called = true}
          os.system('false', &a_block).should be_false
          called.should be_true
        end
      end
    end

    describe '#backticks' do
      it do
        subject.backticks("echo foo").should == "foo\n"
      end

      context 'when it fails' do
        it 'should raise an error' do
          expect {
            OS.new.backticks('false')
          }.to raise_error('Failed: 1')
        end
      end
    end
  end
end
