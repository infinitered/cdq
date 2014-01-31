
module CDQ

  class CDQModelManager

    attr_writer :current

    def initialize(opts = {})
      @config = opts[:config] || CDQConfig.default
    end

    def current
      @current ||= load_model
    end

    def invalid?
      !@current && @config.model_url.nil?
    end

    def log(log_type = nil)
      out =   "\n\n                MODELS"
      out <<  "\n  Model                    |     count |"              
      line =  "\n - - - - - - - - - - - - - | - - - - - |"
      out << line

      self.current.entities.each do |entity| 
        out << "\n  #{entity.name.ljust(25)}|"
        out << " #{CDQ.cdq(entity.name).count.to_s.rjust(9)} |"
      end

      out << line

      entities = CDQ.cdq.models.current.entities
      if entities && (entity_count = entities.length) && entity_count > 0
        out << "\n#{entity_count} models"
        out << "\n\nYou can log a model like so: #{self.current.entities.first.name}.log"
      end

      if log_type == :string
        out
      else
        NSLog out
      end
    end

    private

    def load_model
      if invalid?
        raise "No model file.  Cannot create an NSManagedObjectModel without one."
      else
        NSManagedObjectModel.alloc.initWithContentsOfURL(@config.model_url)
      end
    end

  end

end
