require 'spec_helper.rb'

module GitObjectBrowser::Models
  describe Bindata do
    let(:io) { StringIO.new('abcdefg') }
    subject { Bindata.new(io) }

    describe '#switch_source' do
      it 'should change source temporary' do
        io2 = StringIO.new('ABCDEFG')
        subject.raw(2)
        subject.switch_source(io2) do
          subject.raw(3).should eq 'ABC'
        end
        subject.raw(3).should eq 'cde'
      end
    end

    describe '#raw' do
      it 'should return string' do
        subject.raw(3).should eq 'abc'
      end

      it 'should return empty string and the position does not move when read 0 byte' do
        subject.raw(0).should eq ''
        subject.raw(1).should eq 'a'
        subject.raw(0).should eq ''
        subject.raw(2).should eq 'bc'
      end

      it 'should not raise error if the argument is greater than the real size' do
        subject.raw(100).should eq 'abcdefg'
      end

      it 'should return nil if the position is at the end of stream' do
        subject.bytes(100)
        subject.raw(1).should eq nil
      end
    end

    describe '#bytes' do
      it 'should return byte code array' do
        subject.bytes(3).should eq [97, 98, 99]
      end

      it 'should return empty array and the position does not move when read 0 byte' do
        subject.bytes(0).should eq []
        subject.bytes(1).should eq [97]
        subject.bytes(0).should eq []
        subject.bytes(2).should eq [98, 99]
      end

      it 'should not raise error if the argument is greater than the real size' do
        subject.bytes(100).should eq (97..103).to_a
      end

      it 'should raise error if the position is at the end of stream' do
        subject.bytes(100)
        expect { subject.bytes(1) }.to raise_error
      end
    end

    describe '#byte' do
      it 'should return first byte' do
        subject.byte.should eq 97
        subject.byte.should eq 98
      end

      it 'should raise error if the position is at the end of stream' do
        subject.bytes(100)
        expect { subject.byte }.to raise_error
      end
    end

    describe '#int' do
      it 'should return int value' do
        subject.int.should eq 1633837924
      end

      it 'should raise error if the position is at the end of stream' do
        subject.bytes(100)
        expect { subject.int }.to raise_error
      end
    end

    describe '#hex' do
      it 'should return int value' do
        subject.hex(2).should eq '6162'
      end

      it 'should raise error if the position is at the end of stream' do
        subject.bytes(100)
        expect { subject.hex(1) }.to raise_error
      end
    end

    describe '#binstr' do
      it 'should return int value' do
        subject.binstr(2).should eq '0110000101100010'
      end

      it 'should raise error if the position is at the end of stream' do
        subject.bytes(100)
        expect { subject.binstr(1) }.to raise_error
      end
    end

    describe '#find_char' do
      it 'should not include passed character' do
        subject.find_char('d').should eq 'abc'
        subject.raw(3).should eq 'efg'
      end

      it 'should not raise error if the character is not found' do
        subject.find_char('z').should eq 'abcdefg'
      end
    end

    describe '#skip' do
      it 'should start seek from current position' do
        subject.raw(2)
        subject.skip(2)
        subject.raw(3).should eq 'efg'
      end
    end

    describe '#seek' do
      it 'should seek from beginning' do
        subject.raw(2)
        subject.seek(2)
        subject.raw(3).should eq 'cde'
      end
    end

    describe '#peek' do
      it 'should not move position' do
        subject.raw(3)
        subject.peek(3).should eq 'def'
        subject.raw(3).should eq 'def'
      end
    end

  end
end
