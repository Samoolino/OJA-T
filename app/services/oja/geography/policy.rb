module Oja
  module Geography
    class Policy
      Result = Struct.new(:allowed, :reason, :evidence, keyword_init: true)
      def self.evaluate(policy:, context:)
        new(policy:, context:).evaluate
      end
      def initialize(policy:, context:)
        @policy = (policy || {}).transform_keys(&:to_s)
        @context = (context || {}).transform_keys(&:to_s)
      end
      def evaluate
        return Result.new(allowed: true, reason: "no_geo_restriction", evidence: {}) if @policy.empty?
        required = %w[country_code admin_area_1_code admin_area_2_code locality].select { |k| @policy[k].to_s != "" }
        missing = required.reject { |key| @context[key].to_s != "" }
        return Result.new(allowed: false, reason: "geography_context_missing", evidence: { "missing" => missing }) if missing.any?
        mismatches = required.each_with_object({}) do |key, out|
          expected = Array(@policy[key]).map(&:to_s)
          actual = @context[key].to_s
          out[key] = { "expected" => expected, "actual" => actual } unless expected.include?(actual)
        end
        return Result.new(allowed: false, reason: "geography_mismatch", evidence: { "mismatches" => mismatches }) if mismatches.any?
        Result.new(allowed: true, reason: "geography_match", evidence: @context.slice("country_code", "admin_area_1_code", "admin_area_2_code", "locality"))
      end
    end
  end
end
