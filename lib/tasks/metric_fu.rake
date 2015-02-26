begin  
  require 'metric_fu'  
    
  MetricFu::Configuration.run do |config|  
  end  
    
rescue LoadError  
end  