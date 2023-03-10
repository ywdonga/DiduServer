//
//  UserController.swift
//  
//
//  Created by dyw on 2023/3/9.
//

import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        
    }
    
    func validateIdentityTokenHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let identityToken = try req.content.decode(IdentityToken.self)
        
        // Get the JWK Set from Apple's public keys endpoint
        let jwkSet = try await req.application.apple.verifyJWKSet()
        
        // Verify the identity token signature using the JWK Set
        let signer = JWTSigner.rs256(jwks: jwkSet)
        let verifiedIdentityToken = try JWT<IdentityTokenPayload>(from: identityToken.token, verifiedUsing: signer)
        
        // Verify that the identity token was issued for this app
        guard verifiedIdentityToken.payload.iss == "https://appleid.apple.com" else {
            throw Abort(.badRequest, reason: "Invalid issuer")
        }
        guard verifiedIdentityToken.payload.aud == "com.yourapp.bundleid" else {
            throw Abort(.badRequest, reason: "Invalid audience")
        }
        
        // Verify the identity token nonce
        let nonce = try req.session.get("nonce")
        guard verifiedIdentityToken.payload.nonce == nonce else {
            throw Abort(.badRequest, reason: "Invalid nonce")
        }
        
        // Get the user's email address from the identity token
        let email = verifiedIdentityToken.payload.email
        
        // Lookup or create the user based on their email address
        return User.query(on: req.db)
            .filter(\.$email == email)
            .first()
            .flatMap { existingUser in
                if let user = existingUser {
                    return req.eventLoop.future(user)
                } else {
                    let newUser = User(email: email)
                    return newUser.save(on: req.db).transform(to: newUser)
                }
            }
    }

}
