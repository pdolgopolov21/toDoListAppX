//
//  NetworkService.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

class NetworkService {
    
    static let shared = NetworkService() // Синглтон
    
    private init() {}
    
    private let baseURL = "https://dummyjson.com/todos"

    func fetchTodos(completion: @escaping (Result<[APITask], NetworkError>) -> Void) {
        // Проверяем валидность URL
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Создаем задачу для URLSession. Запуск будет в фоновом потоке по умолчанию.
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Обрабатываем возможные ошибки
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // Декодируем JSON
            do {
                let apiResponse = try JSONDecoder().decode(APITodosResponse.self, from: data)
                completion(.success(apiResponse.todos))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }.resume() // Запускаем задачу
    }
}
