import JWT
import Meow

struct Token: JWTPayload {
    let exp: ExpirationClaim
    let sub: Reference<User>

    init(sub: Reference<User>) {
        // Valid for 1 hour
        self.exp = .init(value: Date().addingTimeInterval(3600))
        self.sub = sub
    }

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
