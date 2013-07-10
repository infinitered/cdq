class AppDelegate
  include CDQ

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    cdq.setup
    true
  end
end

class TopLevel
  include CDQ
end

