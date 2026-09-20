module Oja
  module Idempotency
    module_function
    KEY_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9._:-]{7,255}\z/
    def validate!(key)
      value = key.to_s
      raise ArgumentError, "idempotency_key is required" if value.empty?
      raise ArgumentError, "invalid idempotency_key" unless value.match?(KEY_PATTERN)
      value
    end
    def operation_id(prefix:, idempotency_key:)
      "#{prefix}:#{validate!(idempotency_key)}"
    end
  end
end
