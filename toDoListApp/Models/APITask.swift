//
//  APITask.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import Foundation

struct APITodosResponse: Codable {
    let todos: [APITask]
}

struct APITask: Codable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}
