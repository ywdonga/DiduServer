//
//  UserController.swift
//  
//
//  Created by dyw on 2023/3/9.
//

import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("register", use: register)
        users.post("login", use: login)
    }
    
    func register(req: Request) throws -> EventLoopFuture<User> {
        try User.Create.validate(content: req)
        let userCreate = try req.content.decode(User.Create.self)
        let user = try User(email: userCreate.email, password: Bcrypt.hash(userCreate.password))
        return user.save(on: req.db).map { user }
    }
    
    func login(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loginData = try req.content.decode(User.Login.self)
        return User.query(on: req.db)
            .filter(\.$email == loginData.email)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMapThrowing { user in
                try Bcrypt.verify(loginData.password, created: user.password)
            }
            .flatMap { isAuthenticated in
                if isAuthenticated {
                    req.session.data["userId"] = loginData.email
                    return req.eventLoop.future(.ok)
                } else {
                    return req.eventLoop.future(.unauthorized)
                }
            }
    }
}

extension User {
    struct Create: Content {
        let email: String
        let password: String
    }
    
    struct Login: Content {
        let email: String
        let password: String
    }
}
