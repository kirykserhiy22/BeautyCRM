//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation


final class LocalAuthService {


    private let key = "local_users"



    private func loadUsers() -> [AuthCredentials] {

        guard let data =
                UserDefaults.standard.data(forKey: key),
              let users =
                try? JSONDecoder()
                    .decode(
                        [AuthCredentials].self,
                        from: data
                    )
        else {

            return []
        }


        return users
    }



    private func saveUsers(
        _ users: [AuthCredentials]
    ) {

        let data =
        try? JSONEncoder()
            .encode(users)


        UserDefaults.standard.set(
            data,
            forKey: key
        )
    }



    // MARK: SIGN UP


    func signUp(
        email: String,
        password: String
    ) -> AuthResult {


        let email =
        email
            .lowercased()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )


        guard !email.isEmpty else {

            return .failure(.emptyEmail)
        }


        guard AuthValidator.validateEmail(email)
        else {

            return .failure(.invalidEmail)
        }



        guard AuthValidator.validatePassword(password)
        else {

            return .failure(.weakPassword)
        }



        var users = loadUsers()



        if users.contains(
            where: {
                $0.email == email
            }
        ) {

            return .failure(
                .userAlreadyExists
            )
        }



        let newUser =
        AuthCredentials(
            email: email,
            password: password,
            userID: UUID().uuidString
        )



        users.append(newUser)

        saveUsers(users)



        return .success(
            userID: newUser.userID
        )
    }




    // MARK: LOGIN


    func login(
        email: String,
        password: String
    ) -> AuthResult {


        let email =
        email
            .lowercased()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )



        let users = loadUsers()



        guard let user =
                users.first(
                    where: {
                        $0.email == email
                    }
                )
        else {

            return .failure(
                .userNotFound
            )
        }



        guard user.password == password
        else {

            return .failure(
                .wrongPassword
            )
        }



        return .success(
            userID: user.userID
        )
    }
}
