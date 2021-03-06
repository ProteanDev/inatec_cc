module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class InatecGateway < Gateway
      self.test_url = 'https://www.taurus21.com/pay/'
      self.live_url = 'https://www.taurus21.com/pay/'

      # self.supported_countries = ['US']
      self.default_currency = 'EUR'
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      self.homepage_url = 'http://www.inatec.com'
      self.display_name = 'Inatec'

      def initialize(options = {})
        options[:param_3d] ||= 'non3d'
        requires!(options, :merchant_id, :secret)
        super
      end

      def preauthorize(money, payment, options = {})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, options)
        add_customer_data(post, options)
        add_recurring_params(post, options)
        add_config_data(post)
        commit('backoffice/payment_preauthorize', post)
      end

      def preauthorize_with_recurring(money, payment, options = {})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, options)
        add_customer_data(post, options)
        add_recurring_params(post, options)
        add_config_data(post)
        commit('backoffice/payment_preauthorize', post)
      end

      def preauthorize_with_charge_recurring(money, recurring_id, options = {})
        post = {}
        add_invoice(post, money, options)
        add_recurring_id(post, recurring_id)
        add_address(post, options)
        add_customer_data(post, options)
        add_config_data(post)
        commit('backoffice/payment_preauthorize', post)
      end

      def authorize(money, payment, options = {})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, options)
        add_customer_data(post, options)
        add_config_data(post)
        commit('backoffice/payment_authorize', post)
      end

      def authorize_with_recurring(money, payment, options = {})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, payment)
        add_address(post, options)
        add_customer_data(post, options)
        add_recurring_params(post, options)
        add_config_data(post)
        commit('backoffice/payment_authorize', post)
      end

      def charge_recurring(money, recurring_id, options = {})
        post = {}
        add_invoice(post, money, options)
        add_recurring_id(post, recurring_id)
        add_address(post, options)
        add_customer_data(post, options)
        add_config_data(post)
        commit('backoffice/payment_authorize', post)
      end

      def capture(options = {})
        post = {}
        add_capture_params(post, options)
        add_config_data(post)
        commit('backoffice/payment_capture', post)
      end

      def reversal(options = {})
        post = {}
        add_reversal_params(post, options)
        add_config_data(post)
        commit('backoffice/payment_reversal', post)
      end

      # TO DO need move to other class
      def diagnose(options = {})
        post = {}
        add_diagnose_params(post, options)
        add_config_data(post)
        commit_rep('backoffice/tx_diagnose', post)
      end

      def refund(money, options = {})
        post = {}
        add_refund_params(post, money, options)
        add_config_data(post)
        commit('backoffice/payment_refund', post)
      end

      def generate_signature(post)
        sorted_param_values = post.map { |k, v| [k.downcase, v] }.sort.map { |a| a[1] }.join('')
        sorted_param_values << options[:secret]
        Digest::SHA1.hexdigest(sorted_param_values).downcase
      end

      private

      def add_config_data(post)
        post[:merchantid] = options[:merchant_id]
        post[:param_3d] = options[:param_3d] if options[:param_3d]
        post[:url_return] = options[:url_return] if options[:url_return]
        post[:custom1] = options[:custom1] if options[:custom1]
        post[:signature] = generate_signature(post)
      end

      def add_customer_data(post, options)
        post[:firstname] = options.fetch(:first_name) { |k| raise KeyError.new("missing parameter: #{k}") }
        post[:lastname] = options.fetch(:last_name) { |k| raise KeyError.new("missing parameter: #{k}") }
        post[:email] = options.fetch(:email) { |k| raise KeyError.new("missing parameter: #{k}") }
        post[:customerip] = options.fetch(:ip) { |k| raise KeyError.new("missing parameter: #{k}") }
      end

      def add_address(post, options)
        post[:street] = options.fetch(:address, {}).fetch(:street) { |k| raise KeyError.new("missing parameter in address: #{k}") }
        post[:zip] = options.fetch(:address, {}).fetch(:zip) { |k| raise KeyError.new("missing parameter in address: #{k}") }
        post[:city] = options.fetch(:address, {}).fetch(:city) { |k| raise KeyError.new("missing parameter in address: #{k}") }
        post[:country] = options.fetch(:address, {}).fetch(:country) { |k| raise KeyError.new("missing parameter in address: #{k}") }
      end

      def add_invoice(post, money, options)
        post[:amount] = amount(money)
        post[:currency] = (options[:currency] || currency(money))
        post[:payment_method] = 1 || options[:payment_method]
        post[:orderid] = options.fetch(:order_id) { |k| raise KeyError.new("missing parameter: #{k}") }
      end

      def add_payment(post, payment)
        post[:ccn] = payment.number
        post[:exp_month] = payment.month.to_s.rjust(2, '0')
        post[:exp_year] = payment.year
        post[:cvc_code] = payment.verification_value
        post[:cardholder_name] = "#{payment.first_name} #{payment.last_name}"
      end

      def add_recurring_id(post, recurring_id)
        post[:recurring_id] = recurring_id
      end

      def add_recurring_params(post, options)
        post[:recurring_id] = 'INIT'
      end

      def add_capture_params(post, options)
        post[:transactionid] = options[:transaction_id]
      end

      def add_diagnose_params(post, options)
        post[:transactionid] = options[:transaction_id]
        post[:type] = 'tx'
      end

      def add_reversal_params(post, options)
        post[:transactionid] = options[:transaction_id]
      end

      def add_refund_params(post, money, options)
        post[:transactionid] = options[:transaction_id]
        post[:price] = amount(money)
      end

      def commit(action, parameters)
        response = parse(ssl_post(combine_url(action), encode_parameters(parameters)))
        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          test: test?
        )
      end

      # TO DO need move to other class
      def commit_rep(action, parameters)
        full_url = "https://www.taurus21.com/rep/#{action}"
        response = Hash.from_xml(ssl_post(full_url, encode_parameters(parameters)))
        ::OpenStruct.new({
          success?: response["response"]["process"]["status"] == '0',
          message: response["response"]["process"]["error_message"],
          content: ::OpenStruct.new(response["response"]),
          authorization: authorization_from(response),
          test?: test?}
        )
      end

      def parse(body)
        CGI::parse(body)
      end

      def combine_url(action, parameters = {})
        url = (test? ? test_url : live_url)
        "#{url}#{action}"
      end

      def encode_parameters(parameters)
        URI.encode_www_form(parameters)
      end

      def success_from(response)
        %w(0 2000).include?(response['status'].first)
      end

      def message_from(response)
        response['errormessage'].first
      end

      def authorization_from(response)
      end
    end
  end
end
