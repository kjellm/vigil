require 'spec_helper'

class Vigil
  describe System do

    describe '#system' do
      it do
        subject.system("true").should be_true
      end

      context 'when it fails' do
        it 'should raise an error' do
          sys = System.new
          expect {
            sys.system('false')
          }.to raise_error('Failed')
        end

        it 'should call the block if one is given' do
          sys = System.new
          called = false
          a_block = ->(stat){called = true}
          sys.system('false', &a_block).should be_false
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
            System.new.backticks('false')
          }.to raise_error('Failed: 1')
        end
      end
    end
  end
end
