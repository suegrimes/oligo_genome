# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Configure action mailer
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
             :enable_starttls_auto => true,
             :address => 'smtp.gmail.com',
             :port    => 587,
             :domain  => 'stanford.oligoexome@gmail.com',
             :tls     => true,
#             :authentication => :login,
#             :user_name => 'stanford.oligoexome',
#             :password  => <pswd>
             }
# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = true