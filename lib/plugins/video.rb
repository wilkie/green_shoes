class Shoes
  class Video
    def initialize args
      @initials = args
      args.each do |k, v|
        instance_variable_set "@#{k}", v
      end
      Video.class_eval do
        attr_accessor *args.keys
      end
      args[:real].bus.add_watch do |b, message|
        case message.type
          when Gst::Message::EOS
            @eos = true; pause
          when Gst::Message::WARNING, Gst::Message::ERROR
            p message.parse
          else
            #p message.type
        end
        true
      end
      @app.win.signal_connect('destroy'){@real.stop}
      @stime = 0
    end

    def playing?
      @eos ? false : @playing
    end

    def play
      if @playing
        self.time, @eos = 0, nil
      else
        @stime = clock_time - seek_time
        @ready = @playing  = true
        (self.time, @eos = 0, nil) if @eos
      end
      @real.play
    end

    def pause
      if @playing
        @real.pause
        @stime = clock_time - @stime
        @playing = false
      end
    end
    
    def stop
      @eos = true
      @real.stop
    end

    def time
      seek_time / 1_000_000
    end

    def time=(ms)
      if @ready
        t = ms * 1_000_000
        e = Gst::EventSeek.new 1.0, Gst::Format::TIME, Gst::Seek::FLAG_FLUSH, 
          Gst::SeekType::SET, t, Gst::SeekType::NONE, Gst::ClockTime::NONE
        @real.send_event e
        @stime = @playing ? clock_time - t : t
      end
    end
    
    def seek_time
      @playing ? clock_time - @stime : @stime
    end
    
    def clock_time
      @real.clock ? @real.clock.time : 0
    end
  end
end

class Shoes
  class App
    def video uri
      args = {}
      uri = File.join('file://', uri.gsub("\\", '/').sub(':', '')) unless uri =~ /^(http|https|file):\/\//
      require 'gst'
      v = Gst::ElementFactory.make 'playbin2'
      v.uri = uri
      args[:real], args[:app] = v, self
      Video.new args
    end
  end
end