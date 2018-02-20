Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  config.action_controller.asset_host = Figaro.env.domain_name
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.assets.debug = true
  config.assets.digest = true
  config.assets.raise_runtime_errors = true
  config.action_view.raise_on_missing_translations = true

  config.action_mailer.default_url_options = {
    host: Figaro.env.domain_name,
    protocol: 'http',
  }
  config.action_mailer.asset_host = Figaro.env.mailer_domain_name
  config.action_mailer.smtp_settings = { address: ENV['SMTP_HOST'] || 'localhost', port: 1025 }
  config.action_mailer.default_options = { from: Figaro.env.email_from }

  config.lograge.enabled = true
  config.lograge.ignore_actions = ['Users::SessionsController#active']
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Bullet gem config
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end
