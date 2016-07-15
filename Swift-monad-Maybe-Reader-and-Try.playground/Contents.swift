// Functors
print("--Functors--")
enum Maybe<T> {
    case Just(T)
    case Nothing

    func fmap<U>(f: T -> U) -> Maybe<U> {
        switch self {
        case .Just(let x): return .Just(f(x))
        case .Nothing: return .Nothing
        }
    }
}
print(Maybe.Just(3).fmap { i in i+2 })
print(Maybe.Nothing.fmap { i in i+3 })

// Applicatives
print("\n--Applicatives--")
extension Maybe {
    func apply<U>(f: Maybe<T -> U>) -> Maybe<U> {
        switch f {
        case .Just(let JustF): return self.fmap(JustF)
        case .Nothing: return .Nothing
        }
    }
}
extension Array {
    func apply<U>(fs: [Element -> U]) -> [U] {
        var result = [U]()
        for f in fs {
            for element in self.map(f) {
                result.append(element)
            }
        }
        return result
    }
}

infix operator <*> { associativity left }
func <*><T, U>(f: Maybe<T -> U>, a: Maybe<T>) -> Maybe<U> {
    return a.apply(f)
}
func <*><T, U>(f: [T -> U], a: [T]) -> [U] {
    return a.apply(f)
}

print(Maybe.Just({ i in i + 3 }) <*> Maybe.Just(2))
print([ { i in i + 3 }, { i in i * 2 } ] <*> [1, 2, 3])

//Monads
print("\n--Monads--")
func half(a: Int) -> Maybe<Int> {
    return a % 2 == 0 ? Maybe.Just(a / 2) : Maybe.Nothing
}

extension Maybe {
    func flatMap<U>(f: T -> Maybe<U>) -> Maybe<U> {
        switch self {
        case .Just(let x): return (f(x))
        case .Nothing: return .Nothing
        }
    }
}
infix operator >>= { associativity left }
func >>=<T, U>(a: Maybe<T>, f: T -> Maybe<U>) -> Maybe<U> {
    return a.flatMap(f)
}

print(Maybe.Just(3) >>= half)
print(Maybe.Just(4) >>= half)
print(Maybe.Nothing >>= half)
print(Maybe.Just(20) >>= half >>= half >>= half)

// Reader Monad
print("\n--Reader Monad--")
class Reader<E, A> {
    let g: E -> A
    init(g: E -> A) {
        self.g = g
    }
    func apply(e: E) -> A {
        return g(e)
    }
    func map<B>(f: A -> B) -> Reader<E, B> {
        return Reader<E, B>{ e in f(self.g(e)) }
    }
    func flatMap<B>(f: A -> Reader<E, B>) -> Reader<E, B> {
        return Reader<E, B>{ e in f(self.g(e)).g(e) }
    }
}
func >>=<E, A, B>(a: Reader<E, A>, f: A -> Reader<E, B>) -> Reader<E, B> {
    return a.flatMap(f)
}

func half(i: Float ) -> Reader<Float , Float> {
    return Reader{_ in i/2}
}
let f = Reader{i in i} >>= half >>= half >>= half
f.apply(20) // 2.5

// Sample
struct User {
    var name: String
    var age: Int
}
struct DB {
    var path: String
    func findUser(userName: String) -> User {
        // DB Select operation
        return User(name: userName, age: 29)
    }
    func updateUser(u: User) -> Void {
        // DB Update operation
        print(u.name + " in: " + path)
    }
}

let dbPath = "path_to_db"
func update(userName: String, newName: String) -> Void {
    let db = DB(path: dbPath)
    var user = db.findUser(userName)
    user.name = newName
    db.updateUser(user)
}
update("dummy_id", newName: "Thor")

// Dependency Injection
struct Environment {
    var path: String
}
func updateF(userName: String, newName: String) -> Reader<Environment, Void> {
    return Reader<Environment, Void>{ env in
        let db = DB(path: env.path)
        var user = db.findUser(userName)
        user.name = newName
        db.updateUser(user)
    }
}
let test = Environment(path: "path_to_sqlite")
let production = Environment(path: "path_to_realm")
updateF("dummy_id", newName: "Thor").apply(test)
updateF("dummy_id", newName: "Thor").apply(production)

// Try monad
print("\n--Try Monad--")
enum Try<T> {
    case Successful(T)
    case Failure(ErrorType)
    init(f: () throws -> T) {
        do {
            self = .Successful(try f())
        } catch {
            self = .Failure(error)
        }
    }
    func map<U>(f: T -> U) -> Try<U> {
        switch self {
        case .Successful(let value): return .Successful(f(value))
        case .Failure(let error): return .Failure(error)
        }
    }
    func flatMap<U>(f: T -> Try<U>) -> Try<U> {
        switch self {
        case .Successful(let value): return f(value)
        case .Failure(let error): return .Failure(error)
        }
    }
}

enum DoomsdayComing: ErrorType {
    case Boom
    case Bang
}
let endOfTheWorld = Try {
    throw DoomsdayComing.Bang
}
let result = Try {4/2}
    .flatMap { _ in endOfTheWorld}
print(result)
