# Who is asking. A real app would use its signed-in user. This demo takes a handle from the
# X-Demo-User header (bots) or ?as= (people in a browser), and remembers it in a cookie.
class Visitor < Data.define(:id, :cohort)
  COHORTS = %w[dev alpha beta user].freeze
  HANDLE = /\A(#{COHORTS.join("|")})-\d{2}\z/
  GUEST = /\Aguest-\h{8}\z/

  def self.from(request, cookies)
    header = request.headers["X-Demo-User"]
    return self.for(header) if valid?(header)

    handle = [ request.params[:as], cookies[:visitor] ].find { |candidate| valid?(candidate) }
    handle ||= "guest-#{SecureRandom.hex(4)}"
    cookies.permanent[:visitor] = handle
    self.for(handle)
  end

  def self.for(handle)
    new(id: handle, cohort: handle[HANDLE, 1] || "user")
  end

  def self.valid?(handle)
    handle.is_a?(String) && (handle.match?(HANDLE) || handle.match?(GUEST))
  end

  # A flag's segments name these predicates: FEATURES__ORANGE_BUTTON_SEGMENTS=dev,alpha calls dev? and alpha?.
  def dev? = cohort == "dev"
  def alpha? = cohort == "alpha"
  def beta? = cohort == "beta"

  # A flag's allowlist matches a user's id or email. Demo visitors have no email.
  def email = nil
end
