class AppDelegate
  include CDQ

  # OS X entry point
  def applicationDidFinishLaunching(notification)
    cdq.setup
  end

  # iOS entry point
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    cdq.setup
    true
  end
end

class TopLevel
  include CDQ
end

