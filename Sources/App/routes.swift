import Vapor

func routes(_ app: Application) throws {
    
    app.get { req async in
        "It works!"
    }

    app.get("hello", ":name") { req async -> String in
        
        if let name = req.parameters.get("name"), name == "qw" {
            return "Hello, \(name)!"
        } else {
            return "Hello, world!"
        }
    }
    
    app.on(.POST, "conversation", body: .stream) { req async -> String in
        print(req.body)
        return "12313"
    }
}
